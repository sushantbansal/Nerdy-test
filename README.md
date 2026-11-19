# Sketch Rush

A real-time multiplayer drawing and guessing game built with **Flutter** and **Supabase**.

Players join rooms, take turns drawing a secret word on a shared canvas, and race to guess what's being drawn — Pictionary-style, right from your phone.

## Features

- **Real-time multiplayer** — powered by Supabase Realtime for instant sync across players
- **Drawing canvas** — smooth freehand strokes with color picker and stroke tools
- **Live chat & guessing** — type your guesses in real-time; correct answers are detected automatically
- **Room system** — create or join game rooms with lobby management
- **Turn-based gameplay** — automatic turn rotation with timers, word selection, and hint reveals
- **Scoring & leaderboard** — points for correct guesses and game-over summary screen
- **Anonymous play** — jump in without creating an account

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| State Management | GetX |
| Backend & Realtime | Supabase (Auth, Database, Realtime, Edge Functions) |
| Drawing Engine | perfect_freehand |

## Getting Started

### Prerequisites

- Flutter SDK (3.x+)
- Docker Desktop + [Supabase CLI](https://supabase.com/docs/guides/cli) (local backend), **or** a hosted Supabase project

### Local setup (Supabase via Docker)

See **[LOCAL_SETUP.md](LOCAL_SETUP.md)** for the full guide. Short version:

```bash
# Backend (Docker)
supabase start

# App (defaults to http://127.0.0.1:54321)
flutter pub get
flutter run -d chrome
```

Studio: http://127.0.0.1:54323

### Setup (hosted Supabase)

1. Clone the repository:
   ```bash
   git clone https://github.com/Faze789/sketch_rush.git
   cd sketch_rush
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Pass your project URL and anon key:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

4. Apply SQL in `supabase/migrations/` and deploy `supabase/functions/game-engine` to that project.

## How to Play

1. Open the app and enter a display name
2. Create a new room or join an existing one from the lobby
3. Once enough players join, the game begins
4. The drawer picks a word and sketches it on the canvas
5. Other players type guesses in the chat — first correct guess scores the most points
6. After all rounds, the player with the highest score wins!
