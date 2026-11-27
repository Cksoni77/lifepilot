# Database design

Flyway applies `../lifepilot_backend/src/main/resources/db/migration/` at startup. V1 creates the schema; V2 adds nullable per-user client IDs and unique indexes for retry-safe task, habit and goal imports. Hibernate is configured with `ddl-auto: validate`; it never creates or silently changes production tables. The backend is a sibling project, not a Flutter subdirectory.

| Table | Purpose / relations |
|---|---|
| `users` | UUID account and BCrypt password hash; unique normalized email |
| `refresh_tokens` | SHA-256 token hashes, expiry, revocation; cascades with user |
| `email_verification_tokens`, `password_reset_tokens` | Reserved token storage; workflows are not implemented |
| `user_preferences` | Timezone, theme, notification flags, optional daily bounds |
| `tasks` | User-owned tasks, priority, category, due/reminder timestamps, optional goal |
| `habits`, `habit_weekdays`, `habit_completions` | Frequency, weekday schedule, unique per-day completion history |
| `goals`, `goal_milestones` | Progress constrained to 0–1, optional target date and milestone titles |
| `calendar_events` | Owner-scoped events; calendar event CRUD and overlap checks use timezone-aware timestamps |
| `ai_conversations`, `ai_messages`, `ai_recommendations` | Owner-scoped chat history is persisted; recommendation history is not currently stored |

Foreign keys cascade when an owning account is deleted. Tasks, habits, and goals have user indexes; tasks additionally have due-date/completion indexes. Schedule timestamps use PostgreSQL `TIMESTAMPTZ`; date-only values such as habit completions use `DATE`.

The Flutter Profile screen can import existing task, habit and goal records from the matching legacy local account. It uses authenticated create APIs and stable client IDs; source `SharedPreferences` records remain untouched. Existing accounts must match by email.
