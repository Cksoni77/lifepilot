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

Task create/update accepts title, description, uppercase category (`PERSONAL`, `WORK`, `HEALTH`, `FINANCE`), uppercase priority (`LOW`, `MEDIUM`, `HIGH`), `dueAt`, `reminderAt`, `reminderEnabled`, `estimatedMinutes`, and optional owner-validated `goalId`. Responses use lowercase category/priority values and `dueDate`/`reminderDate`.

## Habits and goals

- Habits: `POST/GET /api/habits`, `PUT/DELETE /api/habits/{id}`, `POST /api/habits/{id}/complete` with `{date}`, `DELETE /api/habits/{id}/completions?date=YYYY-MM-DD`, `GET /api/habits/{id}/history`, `GET /api/habits/statistics`.
- Goals: `POST/GET /api/goals`, `PUT/DELETE /api/goals/{id}`, `PATCH /api/goals/{id}/progress` with `{progress}` in the range 0–1.

## AI

- `POST /api/ai/chat` with `{message, conversationId?}` returns message, intent, task references, recommendations, proposed actions, explanation, confirmation requirement, and provider availability.
- `POST /api/ai/daily-plan` returns ranked pending tasks, no time slots unless a scheduling data source is later added, and questions for missing availability.

Provider-generated actions are never applied. Cross-user IDs return not found.
