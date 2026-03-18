# Production Follow-Up - 2026-03-18

## Current facts

- The current production server is `47.112.98.191`.
- The backend service is `huiyuanyuan-backend`.
- The backend process, local Nginx proxy, and local health checks are healthy on the server.
- The new production database already has the seeded `operator_1` through `operator_10` accounts and the current admin account.
- The old server `47.98.188.141` does not have business data in `products` or `orders`.
- The old server still has 7 customer users, 1 old admin user, and 39 `sms_logs` rows.
- The legacy customer import has been applied on `2026-03-18`.
- Current production user counts are `admin=1`, `operator=10`, `customer=7`, for `18` total users.

## Public ingress findings

- The development machine has a local HTTP proxy configured at `127.0.0.1:7897`.
- Requests sent through that proxy can return `502 Bad Gateway`, which is not a valid signal for the ECS application path.
- A direct request with `--noproxy "*"` reaches TCP port `80`, but if it still does not appear in the ECS Nginx access log, the remaining issue is outside the FastAPI and Gunicorn process chain.
- Use `scripts/verify_public_ingress.ps1` to repeat the proxy-aware diagnosis from the development machine.

Example:

```powershell
.\scripts\verify_public_ingress.ps1
```

## Legacy user import result

- Keep the current production admin and operator accounts unchanged.
- Import only `user_type = 'customer'` rows from the old server.
- Do not overwrite current IDs or phones if conflicts are detected.
- Create a safety backup on the new server before any import is applied.
- Safety backup created on the current server:
  - `/opt/huiyuanyuan/backups/pre_legacy_customer_import_20260318_155852.dump`

Use `scripts/import_legacy_customers.ps1` for preflight or apply mode.

Preflight only:

```powershell
.\scripts\import_legacy_customers.ps1
```

Export legacy customer rows and old `sms_logs` for audit:

```powershell
.\scripts\import_legacy_customers.ps1 -IncludeSmsLogs
```

Apply the customer import to the current production server:

```powershell
.\scripts\import_legacy_customers.ps1 -Apply
```

## Imported result

- Old admin is not imported.
- 7 legacy customer rows were imported.
- Current production user counts moved from:
  - `admin=1`
  - `operator=10`
- To:
  - `admin=1`
  - `operator=10`
  - `customer=7`
