# Database design

Flyway applies `lifepilot_backend/src/main/resources/db/migration/V1__initial_schema.sql` at startup. Hibernate is configured with `ddl-auto: validate`; it never creates or silently changes production tables.

| Table | Purpose / relations |
|---|---|
| `users` | UUID account and BCrypt password hash; unique normalized email |
| `refresh_tokens` | SHA-256 token hashes, expiry, revocation; cascades with user |
| `email_verification_tokens`, `password_reset_tokens` | Reserved token storage; workflows are not implemented |
| `user_preferences` | Timezone, theme, notification flags, optional daily bounds |
| `tasks` | User-owned tasks, priority, category, due/reminder timestamps, optional goal |
| `habits`, `habit_weekdays`, `habit_completions` | Frequency, weekday schedule, unique per-day completion history |
| `goals`, `goal_milestones` | Progress constrained to 0–1, optional target date and milestone titles |
| `calendar_events` | Fixed/user events and time-range constraint; API is not implemented |
| `ai_conversations`, `ai_messages`, `ai_recommendations` | Reserved persistence schema; chat currently does not write these rows |

Foreign keys cascade when an owning account is deleted. Tasks, habits, and goals have user indexes; tasks additionally have due-date/completion indexes. Schedule timestamps use PostgreSQL `TIMESTAMPTZ`; date-only values such as habit completions use `DATE`.

The first migration is intended for a new backend database. It does not import the Flutter app's existing `SharedPreferences` records.
