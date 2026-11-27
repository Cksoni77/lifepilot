# AI design

`POST /api/ai/chat` derives the account UUID from the JWT, loads at most 100 of that user's recent tasks plus that user's habits and goals, and sends only these records and the message to the backend-configured OpenAI Responses API. The provider key is read from `OPENAI_API_KEY`; it is never part of Flutter configuration. The request asks for JSON and has a configurable timeout.

The output is parsed into a structured response. Task references not found among the authenticated user's loaded tasks are removed. A non-empty proposed-action list makes `requiresConfirmation` true. No suggested action is executed.

When no provider key exists, or the provider call/JSON response fails, deterministic replies can answer saved tasks due today, overdue tasks, and task-priority questions. Other questions receive an explicit message that natural-language AI is unavailable.

## Initial priority heuristic

`score = 0.30 × priority + 0.30 × urgency + 0.20 × deadline proximity + 0.20 × goal relevance`. Inputs are on a 0–100 scale; weights are environment-configurable and must sum to 1:

- Priority: high 100, medium 60, low 30.
- Urgency: overdue 100, due today 90, within two days 75, within seven days 55, within 30 days 35, later 15, no deadline 0.
- Deadline proximity: due/overdue 100; otherwise `100 / (daysUntilDue + 1)`; no deadline 0.
- Goal relevance: linked task 100, unlinked task 0.

This is an initial heuristic, not a validated productivity model. Task duration is included in explanations and context, but no calendar availability is available for slot allocation. Daily planning therefore ranks tasks and asks questions instead of inventing a schedule.

Chats are not persisted yet; `conversationId` is accepted for API compatibility but currently unused. Provider content is external processing of the selected saved context; configure/obtain user consent consistent with the deployment's privacy policy before enabling it in production.
