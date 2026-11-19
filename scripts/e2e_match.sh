#!/usr/bin/env bash
# ============================================================================
# MathClash end-to-end test
#
# Exercises the real local Supabase REST API with two authenticated players:
# room creation/discovery, lobby joins, a full 5-question authoritative match,
# duplicate/late answers, reveal data, results, profile stats, achievements,
# leaderboards, rematch, reconnect, practice and account deletion.
#
# Requirements: local Supabase running, psql and jq installed.
# Usage: ./scripts/e2e_match.sh
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="http://127.0.0.1:54321"
DB="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

cd "$ROOT"

status_env="$(supabase status -o env 2>/dev/null)"
ANON="$(printf '%s\n' "$status_env" | sed -n 's/^ANON_KEY="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p')"
if [[ -z "${ANON}" ]]; then
  echo "Could not read the local anon key. Is Supabase running?" >&2
  exit 1
fi

RUN_ID="$(date +%s)-$$"
EMAIL_A="e2e_a_${RUN_ID}@example.com"
EMAIL_B="e2e_b_${RUN_ID}@example.com"
EMAIL_C="e2e_c_${RUN_ID}@example.com"

pass_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf '  \033[32mok\033[0m  %s\n' "$1"
}

fail() {
  printf '  \033[31mFAIL\033[0m %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  if [[ "$expected" != "$actual" ]]; then
    fail "$message (expected '$expected', got '$actual')"
  fi
  pass "$message"
}

assert_jq() {
  local payload="$1"
  shift
  local message="${*: -1}"
  local jq_args=("${@:1:$#-1}")
  if ! printf '%s' "$payload" | jq -e "${jq_args[@]}" >/dev/null 2>&1; then
    fail "$message (payload: $payload)"
  fi
  pass "$message"
}

sql() {
  psql "$DB" -tAc "$1" | tr -d '\r'
}

signup() {
  local email="$1" name="$2"
  curl -sS -X POST "$API/auth/v1/signup" \
    -H "apikey: $ANON" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg e "$email" --arg n "$name" \
      '{email:$e,password:"password123",data:{display_name:$n}}')"
}

rpc() {
  local token="$1" fn="$2" payload="${3:-{\}}"
  curl -sS -X POST "$API/rest/v1/rpc/$fn" \
    -H "apikey: $ANON" \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -d "$payload"
}

expect_rpc_error() {
  local payload="$1" needle="$2" message="$3"
  if printf '%s' "$payload" | jq -e --arg n "$needle" \
      '(.message // .error // "") | tostring | contains($n)' >/dev/null 2>&1; then
    pass "$message"
  else
    fail "$message (payload: $payload)"
  fi
}

state() {
  rpc "$1" math_room_state "$(jq -n --arg r "$2" '{p_room_id:$r}')"
}

advance_until() {
  # Polls the authoritative tick until the requested state is reached.
  local token="$1" room="$2" kind="$3" expected="$4" tries="${5:-40}"
  local current
  for _ in $(seq 1 "$tries"); do
    rpc "$token" math_advance_match "$(jq -n --arg r "$room" '{p_room_id:$r}')" >/dev/null
    current="$(state "$token" "$room")"
    if printf '%s' "$current" | jq -e --arg k "$kind" --arg e "$expected" \
        '.[$k] == $e or (.[$k] != null and .[$k].status == $e)' \
        >/dev/null 2>&1; then
      printf '%s' "$current"
      return 0
    fi
    sleep 0.6
  done
  fail "Timed out waiting for $kind=$expected (last: $current)"
}

submit_answer() {
  local token="$1" room="$2" question="$3" answer="$4"
  rpc "$token" math_submit_answer "$(jq -n \
    --arg r "$room" --arg q "$question" --arg a "$answer" \
    '{p_room_id:$r,p_match_question_id:$q,p_answer:$a}')"
}

play_full_match() {
  # Plays one complete match in the given room and verifies shared questions,
  # server scoring, reveal secrecy and final standings.
  local room="$1" questions="$2" match_label="$3"
  local a_state b_state qid correct wrong response i

  a_state="$(advance_until "$TOKEN_A" "$room" match countdown 1)"
  a_state="$(advance_until "$TOKEN_A" "$room" match question_active 20)"
  assert_jq "$a_state" '.match.status == "question_active"' \
    "$match_label: countdown transitions to the first question"

  for i in $(seq 1 "$questions"); do
    a_state="$(state "$TOKEN_A" "$room")"
    b_state="$(state "$TOKEN_B" "$room")"
    qid="$(printf '%s' "$a_state" | jq -r '.question.id')"
    [[ "$qid" != "null" && -n "$qid" ]] || fail "$match_label: active question missing"
    assert_eq "$qid" "$(printf '%s' "$b_state" | jq -r '.question.id')" \
      "$match_label Q$i: both players receive the same question"
    assert_eq "$(printf '%s' "$a_state" | jq -c '.question.options')" \
      "$(printf '%s' "$b_state" | jq -c '.question.options')" \
      "$match_label Q$i: both players receive the same options"
    assert_jq "$a_state" '.question.correct_answer == null and .question.explanation == null' \
      "$match_label Q$i: answer key is hidden while active"

    correct="$(sql "SELECT correct_answer FROM math_match_questions WHERE id = '$qid';")"
    wrong="$(printf '%s' "$a_state" | jq -r --arg c "$correct" \
      '.question.options[] | select(. != $c)' | head -n 1)"

    if [[ "$i" == "1" ]]; then
      response="$(submit_answer "$TOKEN_A" "$room" "$qid" "not-an-option")"
      assert_jq "$response" '.error == "invalid_answer"' \
        "$match_label: option validation rejects fabricated answers"
      response="$(submit_answer "$TOKEN_A" "$room" "$qid" "$correct")"
      assert_jq "$response" '.success == true' "$match_label: first answer accepted"
      response="$(submit_answer "$TOKEN_A" "$room" "$qid" "$correct")"
      assert_jq "$response" '.error == "already_answered"' \
        "$match_label: duplicate answer rejected"
    else
      response="$(submit_answer "$TOKEN_A" "$room" "$qid" "$correct")"
      assert_jq "$response" '.success == true' "$match_label Q$i: correct answer accepted"
    fi

    response="$(submit_answer "$TOKEN_B" "$room" "$qid" "$wrong")"
    assert_jq "$response" '.success == true' "$match_label Q$i: second player answered"

    a_state="$(state "$TOKEN_A" "$room")"
    b_state="$(state "$TOKEN_B" "$room")"
    assert_jq "$a_state" '.reveal != null and .question.correct_answer != null' \
      "$match_label Q$i: answer key revealed only after close"
    assert_jq "$a_state" --argjson i "$i" \
      '.my_answer.is_correct == true and .my_answer.speed_bonus == true and .my_answer.points == 2' \
      "$match_label Q$i: fastest correct answer earns 1 + 1 speed point"
    assert_eq "$(printf '%s' "$a_state" | jq -r '.leaderboard[0].player_id')" \
      "$ID_A" "$match_label Q$i: leaderboard orders by authoritative points"

    if [[ "$i" == "$questions" ]]; then
      a_state="$(advance_until "$TOKEN_A" "$room" room final_results 30)"
      assert_jq "$a_state" '.final_results != null and (.final_results.standings | length) == 2' \
        "$match_label: final results persisted for both players"
      assert_jq "$a_state" --arg a "$ID_A" \
        '.final_results.standings[0].player_id == $a and .final_results.standings[0].rank == 1 and .final_results.standings[0].result == "win"' \
        "$match_label: winner ranked first"
      assert_jq "$a_state" --arg a "$ID_A" --argjson q "$questions" \
        '.final_results.standings[0].points == ($q * 2)' \
        "$match_label: winner points equal 2 per question"
      assert_jq "$a_state" --argjson q "$questions" \
        '(.final_results.review | length) == $q' \
        "$match_label: full answer review is available"
    else
      advance_until "$TOKEN_A" "$room" match question_active 30 >/dev/null
      a_state="$(state "$TOKEN_A" "$room")"
      assert_eq "$(printf '%s' "$a_state" | jq -r '.match.question_index')" \
        "$((i + 1))" "$match_label Q$i: server advances the shared question index"
    fi
  done
}

echo "MathClash E2E: signing up players"

create_player() {
  local email="$1" name="$2" payload token id
  payload="$(signup "$email" "$name")"
  token="$(printf '%s' "$payload" | jq -r '.access_token // empty')"
  id="$(printf '%s' "$payload" | jq -r '.user.id // empty')"
  [[ -n "$token" && -n "$id" ]] || fail "Could not sign up $name: $payload"
  printf '%s|%s' "$id" "$token"
}

IFS='|' read -r ID_A TOKEN_A <<<"$(create_player "$EMAIL_A" "Ava Eagle")"
IFS='|' read -r ID_B TOKEN_B <<<"$(create_player "$EMAIL_B" "Ben Bear")"
IFS='|' read -r ID_C TOKEN_C <<<"$(create_player "$EMAIL_C" "Cara Cat")"
pass "three authenticated players created"

echo "MathClash E2E: profiles and room discovery"

response="$(rpc "$TOKEN_A" math_update_profile "$(jq -n \
  '{p_display_name:"Ava Eagle",p_avatar_index:2,p_avatar_color:"#00A2FF",p_grade:2}')")"
assert_jq "$response" '.success == true' "profile update accepted"
response="$(rpc "$TOKEN_A" math_update_profile "$(jq -n \
  '{p_display_name:"<script>",p_avatar_index:2,p_avatar_color:"#00A2FF",p_grade:2}')")"
expect_rpc_error "$response" "Use letters" "unsafe display names rejected"
response="$(rpc "$TOKEN_A" math_update_profile "$(jq -n \
  '{p_display_name:"Ava@bad",p_avatar_index:2,p_avatar_color:"#00A2FF",p_grade:2}')")"
expect_rpc_error "$response" "Use letters" "contact details in display names rejected"

ROOM_JSON="$(rpc "$TOKEN_A" math_create_room "$(jq -n \
  '{p_name:"E2E Addition Arena",p_visibility:"public",p_grade:2,
    p_topics:["addition"],p_difficulty:"easy",p_question_count:5,
    p_answer_seconds:12,p_max_players:4,p_speed_bonus_enabled:true,
    p_auto_start:false}')")"
assert_jq "$ROOM_JSON" '.success == true' "public room created"
ROOM_ID="$(printf '%s' "$ROOM_JSON" | jq -r '.room_id')"
ROOM_CODE="$(printf '%s' "$ROOM_JSON" | jq -r '.room_code')"
[[ "$ROOM_CODE" =~ ^[A-HJ-NP-Z2-9]{6}$ ]] || fail "room code is not secure-looking: $ROOM_CODE"
pass "room code uses the unambiguous 6-character alphabet"

response="$(rpc "$TOKEN_B" math_list_rooms '{"p_grade":2,"p_topic":"addition"}')"
assert_jq "$response" --arg r "$ROOM_ID" 'any(.[]; .id == $r and .player_count == 1)' \
  "public room appears in filtered discovery"

response="$(rpc "$TOKEN_B" math_join_room "$(jq -n --arg c "$ROOM_CODE" '{p_room_code:$c}')")"
assert_jq "$response" '.success == true' "second player joins by code"

response="$(rpc "$TOKEN_C" math_join_room "$(jq -n --arg c "$ROOM_CODE" '{p_room_code:$c}')")"
assert_jq "$response" '.success == true' "third player joins"
response="$(rpc "$TOKEN_C" math_leave_room "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')")"
assert_jq "$response" '.success == true' "player can leave before the match"

response="$(rpc "$TOKEN_A" math_start_match "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')")"
assert_jq "$response" '.success == true and .match_id != null' "host starts the match"
response="$(rpc "$TOKEN_B" math_start_match "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')")"
expect_rpc_error "$response" "Only the host" "non-host cannot start the match"

echo "MathClash E2E: full five-question match"
play_full_match "$ROOM_ID" 5 "match 1"

echo "MathClash E2E: profiles, achievements and leaderboards"
PROFILE_A="$(rpc "$TOKEN_A" math_profile '{}')"
assert_jq "$PROFILE_A" '.games_played == 1 and .wins == 1 and .total_points == 10' \
  "winner profile persisted"
assert_jq "$PROFILE_A" '.correct_answers == 5 and .accuracy == 100 and .win_rate == 100' \
  "winner accuracy persisted"
assert_jq "$PROFILE_A" '[.achievements[].code] | contains(["first_match","perfect_match","accuracy_star","speed_champion"])' \
  "achievements unlocked from authoritative results"
assert_jq "$PROFILE_A" '(.recent_matches | length) == 1 and .recent_matches[0].points == 10' \
  "match history visible on profile"

PROFILE_B="$(rpc "$TOKEN_B" math_profile '{}')"
assert_jq "$PROFILE_B" '.games_played == 1 and .losses == 1 and .accuracy == 0' \
  "opponent statistics persisted"

response="$(rpc "$TOKEN_C" math_profile "$(jq -n --arg p "$ID_A" '{p_player_id:$p}')")"
assert_jq "$response" '.is_me == false and .sound_enabled == null and .reduced_motion == null' \
  "public profiles hide private settings"

response="$(rpc "$TOKEN_C" math_room_state "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')")"
expect_rpc_error "$response" "not in this room" "non-members cannot read match state"

echo "MathClash E2E: rematch and leaderboard thresholds"
rpc "$TOKEN_A" math_play_again "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null
rpc "$TOKEN_A" math_start_match "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null
play_full_match "$ROOM_ID" 5 "match 2"
rpc "$TOKEN_A" math_play_again "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null
rpc "$TOKEN_A" math_start_match "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null
play_full_match "$ROOM_ID" 5 "match 3"

response="$(rpc "$TOKEN_A" math_leaderboard '{"p_window":"weekly","p_limit":10}')"
assert_jq "$response" --arg a "$ID_A" 'any(.[]; .player_id == $a and .games == 3 and .points == 30)' \
  "weekly leaderboard aggregates only completed matches"
response="$(rpc "$TOKEN_A" math_leaderboard '{"p_grade":2,"p_window":"all_time"}')"
assert_jq "$response" --arg a "$ID_A" 'any(.[]; .player_id == $a and .is_me == true)' \
  "grade all-time leaderboard after the minimum match count"
response="$(rpc "$TOKEN_A" math_leaderboard '{"p_topic":"addition","p_window":"all_time"}')"
assert_jq "$response" --arg a "$ID_A" 'any(.[]; .player_id == $a)' \
  "topic leaderboard uses match snapshots"

echo "MathClash E2E: reconnect, host transfer and deadline enforcement"
response="$(rpc "$TOKEN_B" math_join_room "$(jq -n --arg c "$ROOM_CODE" '{p_room_code:$c}')")"
assert_jq "$response" '.success == true and .already_joined == true' \
  "reconnect returns the existing membership"

rpc "$TOKEN_A" math_leave_room "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null
response="$(state "$TOKEN_B" "$ROOM_ID")"
assert_jq "$response" --arg b "$ID_B" '.room.host_id == $b' \
  "host transfers to the remaining player"
rpc "$TOKEN_B" math_leave_room "$(jq -n --arg r "$ROOM_ID" '{p_room_id:$r}')" >/dev/null

LATE_ROOM="$(rpc "$TOKEN_A" math_create_room "$(jq -n \
  '{p_name:"Deadline Test",p_visibility:"private",p_grade:1,
    p_topics:["subtraction"],p_difficulty:"easy",p_question_count:3,
    p_answer_seconds:10,p_max_players:2}')")"
LATE_ID="$(printf '%s' "$LATE_ROOM" | jq -r '.room_id')"
LATE_CODE="$(printf '%s' "$LATE_ROOM" | jq -r '.room_code')"
rpc "$TOKEN_B" math_join_room "$(jq -n --arg c "$LATE_CODE" '{p_room_code:$c}')" >/dev/null
rpc "$TOKEN_A" math_start_match "$(jq -n --arg r "$LATE_ID" '{p_room_id:$r}')" >/dev/null
advance_until "$TOKEN_A" "$LATE_ID" match question_active 20 >/dev/null
LATE_Q="$(state "$TOKEN_A" "$LATE_ID" | jq -r '.question.id')"
sleep 10.5
response="$(submit_answer "$TOKEN_B" "$LATE_ID" "$LATE_Q" "0")"
assert_jq "$response" '.error == "time_up"' "answers after the server deadline are rejected"
advance_until "$TOKEN_A" "$LATE_ID" match question_reveal 10 >/dev/null
response="$(state "$TOKEN_B" "$LATE_ID")"
assert_jq "$response" '.my_answer == null' "unanswered players are not blocked or scored"
rpc "$TOKEN_B" math_leave_room "$(jq -n --arg r "$LATE_ID" '{p_room_id:$r}')" >/dev/null

echo "MathClash E2E: adaptive practice"
response="$(rpc "$TOKEN_A" math_next_practice_question '{"p_grade":2}')"
assert_jq "$response" '.id != null and .correct_answer == null and (.options | length) == 4' \
  "practice question hides the answer key"
PRACTICE_ID="$(printf '%s' "$response" | jq -r '.id')"
PRACTICE_CORRECT="$(sql "SELECT correct_answer FROM math_questions WHERE id = '$PRACTICE_ID';")"
ATTEMPT_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
response="$(rpc "$TOKEN_A" math_submit_practice_answer "$(jq -n \
  --arg q "$PRACTICE_ID" --arg a "$PRACTICE_CORRECT" --arg t "$ATTEMPT_ID" \
  '{p_question_id:$q,p_answer:$a,p_attempt_id:$t,p_used_hint:false,p_elapsed_ms:4200}')")"
assert_jq "$response" '.success == true and .is_correct == true and .explanation != null' \
  "practice answer validated on the server"
response="$(rpc "$TOKEN_A" math_submit_practice_answer "$(jq -n \
  --arg q "$PRACTICE_ID" --arg a "$PRACTICE_CORRECT" --arg t "$ATTEMPT_ID" \
  '{p_question_id:$q,p_answer:$a,p_attempt_id:$t,p_used_hint:false,p_elapsed_ms:4200}')")"
assert_jq "$response" '.error == "already_submitted"' "practice attempts are idempotent"
PROFILE_A="$(rpc "$TOKEN_A" math_profile '{}')"
assert_jq "$PROFILE_A" '.practice_questions == 1 and .practice_correct == 1 and .practice_streak >= 1' \
  "practice progress persisted on the profile"
assert_jq "$PROFILE_A" '(.skills | length) >= 1 and .skills[0].attempts == 1' \
  "skill mastery evidence recorded"

echo "MathClash E2E: account deletion and history retention"
MATCH_COUNT_BEFORE="$(sql "SELECT count(*) FROM math_matches WHERE room_id = '$ROOM_ID';")"
rpc "$TOKEN_C" math_delete_my_account '{}' >/dev/null
assert_eq "0" "$(sql "SELECT count(*) FROM players WHERE id = '$ID_C';")" \
  "account deletion removes the player profile"
assert_eq "0" "$(sql "SELECT count(*) FROM auth.users WHERE id = '$ID_C';")" \
  "account deletion removes the auth user"

rpc "$TOKEN_A" math_delete_my_account '{}' >/dev/null
assert_eq "$MATCH_COUNT_BEFORE" "$(sql "SELECT count(*) FROM math_matches WHERE room_id = '$ROOM_ID';")" \
  "deleting a player preserves other players' match history"

rpc "$TOKEN_B" math_delete_my_account '{}' >/dev/null
assert_eq "0" "$(sql "SELECT count(*) FROM players WHERE id IN ('$ID_A','$ID_B');")" \
  "test players cleaned up"

echo
printf '\033[32mAll %d end-to-end assertions passed.\033[0m\n' "$pass_count"
