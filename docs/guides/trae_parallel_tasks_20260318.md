# Trae Parallel Tasks - 2026-03-18

This file is the handoff contract for parallel work between Codex and Trae.

## Status Snapshot

Archived on 2026-03-18 after the payment-account API migration work was completed.

Completed in this round:

- Backend `payment_accounts` API, Alembic `0003`, and backend regression tests were finished by Codex.
- Flutter payment-account flow is now API-driven and no longer uses local `SharedPreferences` storage in the active UI path.
- Default-account selection and mutation failure feedback were added to the payment-management UI.
- Legacy payment-account helpers were removed from `storage_service.dart`, and the old storage-based payment-account test group was removed from `storage_service_test.dart`.
- `ApiService.forTesting()` was added as the test seam for fake notifier/API mutation coverage.
- Trae completed the push-service scope note in `docs/guides/push_service_implementation_guide.md`.
- Focused frontend coverage now includes:
  - `test/models/payment_account_test.dart`
  - `test/providers/payment_provider_test.dart`
  - `test/screens/payment_management_screen_test.dart`

Verification snapshot:

- Use `.\scripts\run_flutter_test_no_proxy.ps1 test\...` on this machine because local proxy env vars break plain `flutter test`.
- Current Flutter analyze result for the full app is down to info-level suggestions only for this slice; no payment-account warnings or errors remain.

Remaining optional follow-up work:

- Broader garbled-text cleanup outside the payment-account flow.
- Push-service implementation remains explicitly out of scope for this round; only the scope/design note is done.

## Recommended Next Trae Scope

Do not reopen the payment-account core flow unless a new regression is found.

No blocking parallel task remains in the payment-account slice.

If Trae continues in a new round, prefer non-overlapping follow-up work:

1. Push pre-implementation planning only:
   - keep `docs/guides/push_service_implementation_guide.md` as the source note
   - refine dependency/version choices and app-entry hook points without shipping Firebase code yet
2. Broader frontend hygiene outside the payment flow:
   - analyze remaining app-wide info-level suggestions
   - clean stale comments or local-only helper code that is no longer used
3. Commit-prep support:
   - help review which new docs/tests/scripts are intended to be committed
   - avoid touching Codex-owned backend files unless a new issue is found

## Goal

Replace the remaining local-only payment-account flow with a real API-driven flow, while avoiding overlap between backend and frontend changes.

## Ownership

### Codex ownership

Codex owns the backend slice and related tests.

Files owned by Codex in this round:

- `huiyuyuan_app/backend/routers/users.py`
- `huiyuyuan_app/backend/schemas/user.py`
- `huiyuyuan_app/backend/store.py`
- `huiyuyuan_app/backend/tests/test_payment_accounts.py`
- `huiyuyuan_app/backend/migrations/versions/20260318_0003_create_payment_accounts.py`

Codex will not edit the Flutter payment UI/provider in this round beyond the already-finished removal of default mock accounts.

Current backend source of truth for this feature:

- Alembic migration: `backend/migrations/versions/20260318_0003_create_payment_accounts.py`
- Router contract: `backend/routers/users.py`

Note:

- `backend/init_db.sql` is still the historical bootstrap script and has not been fully resynced for `payment_accounts` in this round. For any fresh environment, prefer running Alembic migrations through `0003`.

### Trae ownership

Trae owns the Flutter frontend integration for payment accounts.

Primary files for Trae:

- `huiyuyuan_app/lib/models/payment_account.dart`
- `huiyuyuan_app/lib/providers/payment_provider.dart`
- `huiyuyuan_app/lib/screens/payment_management_screen.dart`
- `huiyuyuan_app/lib/config/api_config.dart`
- `huiyuyuan_app/lib/services/api_service.dart`
- `huiyuyuan_app/lib/screens/profile/profile_screen.dart`

Optional follow-up files for Trae after payment API integration is done:

- `huiyuyuan_app/lib/screens/admin/admin_dashboard.dart`
- `huiyuyuan_app/lib/screens/product/search_screen.dart`
- `huiyuyuan_app/lib/screens/profile/favorite_list_screen.dart`
- `huiyuyuan_app/lib/screens/profile/browse_history_screen.dart`
- `huiyuyuan_app/lib/services/push_service.dart`

Trae should not edit the backend files listed in the Codex ownership section.

## Backend API Contract

Base prefix: `/api/users`

### 1. List payment accounts

`GET /api/users/payment-accounts`

Response:

```json
[
  {
    "id": "payacc_ab12cd34",
    "user_id": "customer_123",
    "name": "Main card",
    "type": "bank",
    "account_number": "622233445566",
    "bank_name": "Test Bank",
    "qr_code_url": null,
    "is_active": true,
    "is_default": true,
    "created_at": "2026-03-18T13:00:00Z",
    "updated_at": "2026-03-18T13:00:00Z"
  }
]
```

### 2. Create payment account

`POST /api/users/payment-accounts`

Request:

```json
{
  "name": "Main card",
  "type": "bank",
  "account_number": "622233445566",
  "bank_name": "Test Bank",
  "qr_code_url": null,
  "is_active": true,
  "is_default": true
}
```

Response: same shape as list item.

### 3. Update payment account

`PUT /api/users/payment-accounts/{account_id}`

Request shape is the same as create.

Response: same shape as list item.

### 4. Delete payment account

`DELETE /api/users/payment-accounts/{account_id}`

Response:

```json
{
  "success": true
}
```

### 5. Profile response

`GET /api/users/profile`

Now includes optional `payment_account_id`:

```json
{
  "id": "customer_123",
  "username": "user",
  "payment_account_id": "payacc_ab12cd34",
  "user_type": "customer"
}
```

## Trae Task Breakdown

### P0. Payment accounts API integration [Done]

Replace local `SharedPreferences`-only behavior with API-driven behavior.

Required work:

- Added API endpoint constants for payment accounts.
- Replaced local storage behavior in `payment_provider.dart` with `ApiService`.
- Backend `type` strings now map to `bank`, `alipay`, `wechat`, `cash`, `other`.
- List/create/update/delete are wired to `/api/users/payment-accounts`.
- Empty/loading/error/default-account flows are handled in the payment-management UI.
- Default fake accounts are no longer recreated locally.
- Existing add/edit/delete/toggle-active UX remains, now with explicit mutation error feedback.

Acceptance:

- Opening payment-management page loads data from `/api/users/payment-accounts`.
- Empty account list shows empty state, not mock accounts.
- Add/edit/delete/default-account flows round-trip against backend.
- No direct `SharedPreferences` dependency remains in the active payment-account flow.

### P1. Frontend test coverage [Done]

Add or update focused tests for:

- Payment-account model parsing and nullable-field behavior.
- Payment provider state transitions and error-message behavior.
- Payment-management error state, default-action failure, and delete-failure snackbar behavior.

Use this command on this machine because `HTTP_PROXY` breaks plain `flutter test`:

```powershell
.\scripts\run_flutter_test_no_proxy.ps1 test\...
```

### P2. Text/encoding cleanup [Done]

Trae audited the planned frontend surfaces in this slice and reported the current Chinese copy as clean in:

- `admin_dashboard.dart`
- `search_screen.dart`
- `favorite_list_screen.dart`
- `browse_history_screen.dart`
- `profile_screen.dart`

No further text cleanup is required for the payment-account handoff in this round.

### P3. Push-service scoping only [Done]

Do not implement full push in this round unless explicitly requested.

Completed scope:

- Audit `push_service.dart`
- List missing dependencies and app-entry hooks
- Produce a short implementation note in `docs/guides/push_service_implementation_guide.md`

### P4. Test hardening follow-up [Done]

Additional test work completed after the initial handoff:

- `payment_provider_test.dart` now includes fake-`ApiService` mutation coverage for load/add/update/delete/toggle-active success and failure paths.
- `ApiService.forTesting()` is the supported seam for these notifier-level tests.

## Notes For Trae

- Codex is already handling the backend API and backend tests.
- Avoid editing `backend/routers/users.py`, `backend/schemas/user.py`, migrations, or backend tests.
- If a frontend change depends on a backend field rename, update this task file instead of guessing.
