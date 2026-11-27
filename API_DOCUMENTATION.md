# API documentation

All responses are JSON except successful delete/logout operations, which may have an empty body. Protected routes require `Authorization: Bearer <accessToken>`. Error objects contain `status`, `error`, `message`, and `timestamp`. Account/domain ownership is derived from the JWT.

## Authentication and user

| Method | Path | Body / result |
|---|---|---|
| POST | `/api/auth/register` | `{name,email,password}`; returns access/refresh tokens and user |
| POST | `/api/auth/login` | `{email,password}`; returns access/refresh tokens and user |
| POST | `/api/auth/refresh` | `{refreshToken}`; rotates the stored refresh-token hash |
| POST | `/api/auth/logout` | `{refreshToken}`; revokes refresh token |
| GET / PUT | `/api/users/me` | Current profile; PUT accepts `{name}` |
| GET / PUT | `/api/users/me/preferences` | Current user's timezone/theme/notification preferences |
| POST | `/api/auth/forgot-password` | Returns 503 until email delivery is configured |
| POST | `/api/auth/reset-password` | Returns 503 until email delivery is configured |
| POST | `/api/auth/verify-email` | Returns 503 until email delivery is configured |

Registration currently does not verify email addresses. Passwords must be 12–72 characters.

## Tasks

- `POST /api/tasks` and `GET /api/tasks?search=&status=&sort=`
- `GET /api/tasks/{id}`, `PUT /api/tasks/{id}`, `DELETE /api/tasks/{id}`
- `PATCH /api/tasks/{id}/complete` with `{completed: true|false}`
- `GET /api/tasks/today`, `/api/tasks/overdue`, `/api/tasks/upcoming`

Task create/update accepts title, description, uppercase category (`PERSONAL`, `WORK`, `HEALTH`, `FINANCE`), uppercase priority (`LOW`, `MEDIUM`, `HIGH`), `dueAt`, `reminderAt`, `reminderEnabled`, `estimatedMinutes`, and optional owner-validated `goalId`. Task creation also accepts optional `clientId` for retry-safe imports and `completed`/`completedAt` to preserve imported completion state. Responses use lowercase category/priority values and `dueDate`/`reminderDate`.

## Habits and goals

- Habits: `POST/GET /api/habits`, `PUT/DELETE /api/habits/{id}`, `POST /api/habits/{id}/complete` with `{date}`, `DELETE /api/habits/{id}/completions?date=YYYY-MM-DD`, `GET /api/habits/{id}/history`, `GET /api/habits/statistics`.
- Goals: `POST/GET /api/goals`, `PUT/DELETE /api/goals/{id}`, `PATCH /api/goals/{id}/progress` with `{progress}` in the range 0–1.

Habit and goal create requests also accept optional `clientId`. For tasks, habits, and goals, a repeated create with the same `clientId` returns the existing record for the authenticated account. These IDs support safe retry of local imports; they do not establish ownership.

## Calendar events

- `GET /api/calendar/events`
- `POST /api/calendar/events` and `PUT /api/calendar/events/{id}` accept `{title, startsAt, endsAt, fixed, source}`.
- `DELETE /api/calendar/events/{id}`
- `GET /api/calendar/conflicts?startsAt=<offset-date-time>&endsAt=<offset-date-time>&excludeEventId=<uuid>` returns `{available, conflicts}`. Intervals overlap when `existing.startsAt < requested.endsAt` and `existing.endsAt > requested.startsAt`.

All event routes are authenticated and owner-scoped. The endpoint reports conflicts but does not silently reject overlapping manual calendar entries.

## AI

- `POST /api/ai/chat` with `{message, conversationId?}` returns message, intent, task references, recommendations, proposed actions, explanation, confirmation requirement, and provider availability.
- `GET /api/ai/conversations` lists the authenticated user's conversations; `GET /api/ai/conversations/{id}/messages` returns that conversation's messages. Chat messages are persisted and previous turns are included in bounded provider context.
- `POST /api/ai/daily-plan` returns ranked pending tasks, no time slots unless a scheduling data source is later added, and questions for missing availability.

Provider-generated actions are never applied. Cross-user IDs return not found.
