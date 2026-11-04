# Testing

## Commands

```powershell
flutter analyze
flutter test
mvn -f lifepilot_backend\pom.xml test
```

Backend unit tests cover recommendation ordering/weights, JWT subject validation, BCrypt hashing, and task-owner scoping. Flutter tests use a mocked HTTP client; normal tests do not call OpenAI.

## Validation record

- Before implementation: `flutter analyze` reported no issues and `flutter test` passed all 47 tests.
- During implementation: Flutter analysis detected a misplaced helper and an unused test import; both were fixed.
- Maven compiled the initial backend core successfully before the final test/entity additions.
- Final Flutter tests and final Maven tests were not run because the tool permission prompt for those commands was denied. PostgreSQL integration tests/server startup were not run because no PostgreSQL server was available and Docker Desktop was not running.
