# MathClash - K-5 Multiplayer Math Game

A real-time multiplayer math competition game built with **Flutter** and **Supabase**. Children in Kindergarten through Grade 5 compete by answering math questions in real-time with speed bonuses and fair scoring.

## Features

- **Real-time Multiplayer** - Compete with friends in live rooms
- **Grade-Appropriate Questions** - K-5 curriculum covering addition, subtraction, multiplication, division, and more
- **Fair Scoring** - +1 for correct answer, +1 speed bonus for fastest correct (max 2 per question)
- **Public & Private Rooms** - Create private rooms with shareable codes or join public rooms
- **Live Leaderboards** - Track your progress and compete globally
- **Player Profiles** - Stats, achievements, win rate, accuracy tracking
- **Practice Mode** - Learn and improve at your own pace
- **Safe for Kids** - No public chat, child-safe design

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) with GetX |
| Backend | Supabase (Auth, PostgreSQL, Realtime, Edge Functions) |
| State Management | GetX |
| UI | Material Design 3 with custom candy arcade theme |

## Game Rules

- **5 questions per match** by default
- **15-20 seconds per question**
- **Correct answer**: +1 point
- **Speed bonus**: +1 extra point for fastest correct answer (only if unique)
- **Incorrect/Unanswered**: 0 points
- **Max per question**: 2 points, **Max per match**: 10 points
- **Tiebreaker**: Highest correct count, then lowest response time

## Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Supabase CLI (for local development) or hosted Supabase project

### Local Setup
```bash
# Start local Supabase
supabase start

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

### Environment Variables
Use `--dart-define` for production:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### Database Setup
Apply migrations in `supabase/migrations/` to your Supabase project.
Deploy edge functions from `supabase/functions/` to your project.

## Project Structure

```
lib/
├── app/
│   ├── core/           # Constants, theme, enums, utils
│   ├── data/           # Models, providers
│   ├── domain/         # Services (scoring, question generation)
│   ├── modules/        # Feature modules (home, match, lobby, etc.)
│   └── routes/         # Navigation
supabase/
├── functions/          # Edge functions (math-game-engine, room-functions)
└── migrations/         # Database schema
```

## Testing

```bash
flutter test
flutter analyze
```
