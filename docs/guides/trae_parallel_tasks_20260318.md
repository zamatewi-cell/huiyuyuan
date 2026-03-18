# Trae Parallel Tasks - 2026-03-18

This file is the handoff contract for parallel work between Codex and Trae.

## Goal

Replace the remaining local-only payment-account flow with a real API-driven flow, while avoiding overlap between backend and frontend changes.

## Ownership

### Codex ownership

Codex owns the backend slice and related tests.

Files owned by Codex in this round:

- `huiyuanyuan_app/backend/routers/users.py`
- `huiyuanyuan_app/backend/schemas/user.py`
- `huiyuanyuan_app/backend/store.py`
- `huiyuanyuan_app/backend/tests/test_payment_accounts.py`
- `huiyuanyuan_app/backend/migrations/versions/20260318_0003_create_payment_accounts.py`

Codex will not edit the Flutter payment UI/provider in this round beyond the already-finished removal of default mock accounts.

Current backend source of truth for this feature:

- Alembic migration: `backend/migrations/versions/20260318_0003_create_payment_accounts.py`
- Router contract: `backend/routers/users.py`

Note:

- `backend/init_db.sql` is still the historical bootstrap script and has not been fully resynced for `payment_accounts` in this round. For any fresh environment, prefer running Alembic migrations through `0003`.

### Trae ownership

Trae owns the Flutter frontend integration for payment accounts.

Primary files for Trae:

- `huiyuanyuan_app/lib/models/payment_account.dart`
- `huiyuanyuan_app/lib/providers/payment_provider.dart`
- `huiyuanyuan_app/lib/screens/payment_management_screen.dart`
- `huiyuanyuan_app/lib/config/api_config.dart`
- `huiyuanyuan_app/lib/services/api_service.dart`
- `huiyuanyuan_app/lib/screens/profile/profile_screen.dart`

Optional follow-up files for Trae after payment API integration is done:

- `huiyuanyuan_app/lib/screens/admin/admin_dashboard.dart`
- `huiyuanyuan_app/lib/screens/product/search_screen.dart`
- `huiyuanyuan_app/lib/screens/profile/favorite_list_screen.dart`
- `huiyuanyuan_app/lib/screens/profile/browse_history_screen.dart`
- `huiyuanyuan_app/lib/services/push_service.dart`

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

### P0. Payment accounts API integration

Replace local `SharedPreferences`-only behavior with API-driven behavior.

Required work:

- Add API endpoint constants for payment accounts.
- Change `payment_provider.dart` from local storage to `ApiService`.
- Parse backend `type` strings: `bank`, `alipay`, `wechat`, `cash`, `other`.
- Support list, create, update, delete.
- Keep empty/loading/error states correct.
- Do not recreate default fake accounts locally.
- Preserve current add/edit/delete/toggle-active UX.

Acceptance:

- Opening payment-management page loads data from `/api/users/payment-accounts`.
- Empty account list shows empty state, not mock accounts.
- Add/edit/delete round-trip against backend successfully.
- No direct `SharedPreferences` dependency remains in the payment-account flow.

### P1. Frontend test coverage

Add or update focused tests for:

- Payment-account model parsing.
- Payment provider success/error states.
- Payment-management empty state.

Use this command on this machine because `HTTP_PROXY` breaks plain `flutter test`:

```powershell
.\scripts\run_flutter_test_no_proxy.ps1 test\...
```

### P2. Text/encoding cleanup

After P0 is merged, clean obvious garbled UI copy in:

- `admin_dashboard.dart`
- `search_screen.dart`
- `favorite_list_screen.dart`
- `browse_history_screen.dart`
- `payment_management_screen.dart`

This is lower priority than payment API integration.

### P3. Push-service scoping only

Do not implement full push in this round unless explicitly requested.

Allowed scope:

- Audit `push_service.dart`
- List missing dependencies and app-entry hooks
- Produce a short implementation note

## Notes For Trae

- Codex is already handling the backend API and backend tests.
- Avoid editing `backend/routers/users.py`, `backend/schemas/user.py`, migrations, or backend tests.
- If a frontend change depends on a backend field rename, update this task file instead of guessing.
