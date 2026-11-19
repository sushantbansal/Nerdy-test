# Local setup (Supabase via Docker)

## Prerequisites

- Docker Desktop running
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- Flutter SDK 3.x+ (`brew install --cask flutter`)

## 1. Start Supabase (Docker)

From the project root:

```bash
supabase start
```

Useful URLs (from `supabase status`):

| Service   | URL                         |
|-----------|-----------------------------|
| API       | http://127.0.0.1:54321      |
| Studio    | http://127.0.0.1:54323      |
| DB        | postgresql://postgres:postgres@127.0.0.1:54322/postgres |

Migrations under `supabase/migrations/` apply automatically on start.
Anonymous sign-in is enabled in `supabase/config.toml`.

Reset DB + re-apply migrations anytime:

```bash
supabase db reset
```

Stop:

```bash
supabase stop
```

## 2. App credentials

The app defaults to the local Docker stack:

- URL: `http://127.0.0.1:54321`
- Anon key: local demo JWT (see `lib/app/core/constants/supabase_constants.dart`)

Confirm keys with:

```bash
supabase status -o env
```

## 3. Run the Flutter app

```bash
flutter pub get
flutter devices
flutter run -d chrome          # web (easiest for local API)
# or
flutter run -d macos
# or pick a simulator/device from `flutter devices`
```

**Android emulator** — use `http://10.0.2.2:54321` instead of `127.0.0.1`:

```bash
flutter run -d emulator-5554 \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

**Physical phone** — `127.0.0.1` is the phone itself. Use your Mac’s LAN IP (e.g. `http://192.168.x.x:54321`) the same way with `--dart-define`.

## 4. Edge function

`game-engine` is served automatically by local Supabase at:

`http://127.0.0.1:54321/functions/v1/game-engine`

To serve with live reload while editing:

```bash
supabase functions serve game-engine --env-file supabase/.env.local
```

## Quick checklist

1. Open Docker Desktop
2. `supabase start`
3. `flutter pub get && flutter run -d chrome`
4. Enter a display name → create/join a room
