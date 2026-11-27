# Security

- BCrypt password hashes are stored server-side. Flutter does not persist raw passwords.
- Flutter access/refresh tokens use `flutter_secure_storage`; the legacy local password fields and local session key are removed on first use of the new auth service. Legacy profile data is retained.
- Access JWTs are HMAC-signed and expire after 15 minutes by default. Refresh tokens are random, stored only as SHA-256 hashes, rotated on refresh, and revoked on logout. Access tokens already issued remain valid until expiry.
- Domain repository methods filter by authenticated owner ID; goal references are also validated against that owner.
- DTOs use Bean Validation; JPA repositories and parameterized JDBC avoid string-built SQL.
- OpenAI key and database/JWT secrets are backend environment variables only. Never commit `.env` or use development credentials in production.
- Production must use HTTPS. HTTP cleartext is allowed only in Android debug builds for local development.
- CORS origins are explicit and configurable.

## Known gaps before production

Email verification/reset workflows, auth/AI rate limiting, access-token revocation, security audit logging, and automated dependency/SAST scans are not implemented. No email endpoint pretends success: those operations return 503. Configure strong secrets, TLS termination, restricted CORS, provider privacy/consent, and monitoring before any public deployment.
