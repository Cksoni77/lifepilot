# Implementation status

## Inspected baseline

- Existing Flutter app is feature-oriented and had 47 passing tests and a clean `flutter analyze` baseline before these changes.
- Authentication, tasks, habits, goals, and settings were device-local. Local passwords and account data were in `SharedPreferences`; the AI service was deliberately disconnected.
- Available toolchain: Flutter 3.44.2 / Dart 3.12.2, Java 17, Maven 3.9.9. Docker is installed but its daemon was not running. PostgreSQL was not available.
- A Git checkpoint branch, `backup/lifepilot-before-implementation`, points to the original clean `main` commit.

## Implemented in this change

- Added a Java 17 / Spring Boot 3.4.5 Maven backend with Flyway schema, PostgreSQL configuration, BCrypt passwords, signed short-lived JWT access tokens, hashed/rotating refresh tokens, and authenticated current-user/profile endpoints.
- Added owner-scoped task, habit, goal, and preference API operations. Task-to-goal references are validated against the authenticated owner.
- Added deterministic recommendation scoring and daily-plan/chat endpoints. The plan does not invent time slots when availability and calendar commitments are unknown.
- Added the OpenAI Responses API client, configured only from backend environment variables, with bounded context, response validation, relevant-task reference filtering, timeout handling, and deterministic answers if the provider is not configured or unavailable.
- Replaced Flutter local auth/task/habit/goal reads and writes with REST operations. JWTs are stored with `flutter_secure_storage`; network failures are surfaced as errors. Legacy password/token keys are scrubbed while local task/habit/goal payloads are left untouched.
- Added local-development API URL configuration and Android debug-only cleartext traffic support.
- Added API, architecture, setup, database, AI, security, and testing documentation.

## Incomplete / requires setup or further work

- PostgreSQL server startup, Flyway application, end-to-end auth, and networked Flutter workflows could not be verified here because Docker's daemon and a PostgreSQL server were unavailable.
- Latest verification: `flutter analyze` passed, `flutter test` passed all 51 tests, and `mvn test` passed all 11 backend tests. PostgreSQL startup and end-to-end network flows remain unverified.
- `flutter analyze` passes on the final Flutter changes. `git diff --check` reports no whitespace errors; Git emitted only line-ending conversion warnings for generated platform plugin files.
- Email verification and password reset endpoints deliberately return `503 Service Unavailable`; no email delivery provider is configured, and accounts are not yet email-verified.
- Authentication and AI rate limiting, access-token denylisting, refresh-token cleanup, and operational monitoring are not implemented. Logout revokes refresh tokens; existing access JWTs remain valid until their short expiry.
- Backend calendar-event CRUD and conflict checking are implemented. Flutter still presents tasks by date rather than managing calendar events; daily planning does not allocate time slots.
- AI conversations/messages are persisted and owner-checked. Suggested actions remain proposals and are not executed.
- Flutter preferences still use local storage; the authenticated backend preferences API is present but is not yet wired to the settings UI.
- The Profile screen provides a confirmed, retry-safe import of matching legacy local tasks, habits, and goals, including habit completion history and task-goal links. Original `SharedPreferences` records are not deleted. The import requires the authenticated account email to match the retained legacy profile.
- Flutter does not yet expose the backend's task-goal relationship in the task editor or show structured daily-plan results.
- Offline cache/synchronization is not implemented. Backend-dependent screens require network access.

## Acceptance snapshot

| Area | Status |
|---|---|
| Flutter API/auth/domain integration | Implemented; analysis and all 51 tests pass |
| Backend compilation | `mvn test` passes all 11 tests |
| PostgreSQL persistence | Schema/migration implemented; runtime not verified |
| User data isolation | Owner-scoped repository queries implemented; authorization test added, not run |
| AI with saved user context | Implemented when `OPENAI_API_KEY` is set; provider path not exercised |
| Email workflows, Flutter calendar-event UI, automatic slot scheduling | Incomplete, explicitly documented |
