# Transformation Plan: SketchRush -> K-5 Multiplayer Math Game

## Current Architecture (Audit)
- **Framework**: Flutter (Dart 3.10.7), GetX for state management
- **Backend**: Supabase (Auth, PostgreSQL, Realtime, Edge Functions in Deno)
- **Game Type**: Drawing & guessing (Pictionary-style) - turn-based
- **Real-time**: Supabase Realtime (Postgres changes + Broadcast)
- **Auth**: Email/password auth via Supabase Auth
- **DB Schema**: players, game_rooms, room_players, game_turns, chat_messages, word_bank + enums
- **Game Engine**: Supabase Edge Function `game-engine` handling start_game, select_word, submit_guess, etc.
- **Routes**: splash, auth, lobby, room, game
- **Tests**: Minimal smoke test only

## Target Architecture (K-5 Math Game)
Keep Flutter + GetX + Supabase stack. Transform game mechanics completely.

### Key Changes Needed
1. **Rename/rebrand**: App name, theme/colors to match candy arcade style from designs
2. **Data Models**: New models for math questions, matches, answer submissions, player profiles with full stats, achievements, skills
3. **DB Schema**: Major overhaul - questions/question_bank, math_matches, match_participants, match_questions (snapshots), answer_submissions, player_skill_progress, achievements, player_achievements, etc.
4. **Game Flow**: Real-time quiz competition - all players answer same questions simultaneously with timer, server-authoritative scoring
5. **Room System**: Keep room structure but adapt for math - grade/topic/difficulty/questions_per_match/time_per_question
6. **Game Engine**: Rewrite edge function or add new logic for math game flow
7. **UI/UX**: Implement designs from design/ folder - speedway arena, lobby, question screen, results, podium
8. **Question Engine**: Generate/validate age-appropriate math questions by grade/topic
9. **Scoring**: +1 correct, +1 speed bonus for fastest correct (max 2 per question, 10 per 5-question match)
10. **Profiles/Stats**: Full player stats as specified
11. **Leaderboards**: Multiple leaderboard views

### Milestones
1. **M1: Audit & Planning** - DONE (this plan)
2. **M2: Core Domain & Question Engine** - Question models/generators, scoring logic, room/match state machine
3. **M3: DB Schema & Migrations** - New schema for math game
4. **M4: Auth & Profiles** - Enhance player profiles
5. **M5: Room Management** - Adapt rooms for math config
6. **M6: Real-time Match Engine** - Server-authoritative math match flow
7. **M7: UI Implementation** - Implement math game UI per designs
8. **M8: Testing & Polish** - Tests, security, docs

### Risks
- Major breaking change to existing game logic
- Need to maintain backward compatibility? Or replace completely - task says "transform" so replace
- Supabase edge functions need rewriting
- Complex real-time sync requirements
