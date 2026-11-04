# Setup guide (Windows)

## Requirements

- Flutter 3.44+ / Dart 3.12+
- Java 17 and Maven 3.9+
- PostgreSQL 15+ (or Docker Desktop with PostgreSQL image access)

Java 17 is used because it is installed in the inspected environment; the backend Maven build targets Java 17.

## 1. Start PostgreSQL

With Docker Desktop running:

```powershell
docker run --name lifepilot-postgres `
  -e POSTGRES_DB=lifepilot `
  -e POSTGRES_USER=lifepilot `
  -e POSTGRES_PASSWORD=replace-with-a-local-password `
  -p 5432:5432 -d postgres:16
```

Choose a real local password and use the same value in `DATABASE_PASSWORD`. Flyway creates the schema automatically when Spring Boot starts.

## 2. Configure and run the backend

Copy `.env.example` for reference; Spring Boot does not load dotenv files automatically. In PowerShell, set each variable in the terminal that will run Maven:

```powershell
$env:DATABASE_URL = 'jdbc:postgresql://localhost:5432/lifepilot'
$env:DATABASE_USERNAME = 'lifepilot'
$env:DATABASE_PASSWORD = 'replace-with-your-local-password'
$env:JWT_SECRET = python -c "import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())"
$env:OPENAI_API_KEY = ''
mvn -f lifepilot_backend\pom.xml spring-boot:run
```

`JWT_SECRET` must be a base64-encoded random key of at least 32 bytes. `OPENAI_API_KEY` is optional; without it, deterministic saved-task answers still work.

## 3. Run Flutter

In another terminal:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

- Android emulator: `http://10.0.2.2:8080`
- Physical device: `http://<computer-LAN-IP>:8080`; allow the backend port through the local firewall.
- iOS simulator: `http://localhost:8080` only after configuring the development App Transport Security exception; production must use HTTPS.
- Flutter web: use a local URL and add that exact origin to `CORS_ALLOWED_ORIGINS`.

The Android debug manifest allows local HTTP; release builds do not enable cleartext traffic. Deploy behind HTTPS and pass the HTTPS API URL using `--dart-define`.

## Existing local data

The API cutover does not import existing SharedPreferences task/habit/goal records. They are left on the device; do not clear app data while migrating. Old local auth secrets are scrubbed and users must register/login on the backend. A supported user-facing export/import workflow is still required before users can move existing records into PostgreSQL or another device.
