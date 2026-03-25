# Agent B - Frontend Quality Engineer Roadmap

> Last updated: 2026-03-25

---

## Completed

### B1: Mock Data Elimination
- [x] Replace hardcoded products/shops/orders/favorites with API calls + static fallback
- [x] NotificationCenter: deleted _generateSampleData() (6 hardcoded items)
- [x] ShopRadar: deleted _loadMockData() (5 hardcoded shops)
- [x] BrowseHistory: replaced "Product {id}" with real product name/price/image
- [x] FavoriteList: added real product images via Image.network
- [x] ContactService (new): API-first contact record management
- [x] LogisticsScreen: StatelessWidget -> StatefulWidget, real API data

### B2: Payment Security Fix
- [x] PaymentScreen: removed direct Dio() + Bearer mock_token hardcode
- [x] Removed auto-success simulation (pollCount >= 3 auto-redirect)
- [x] simulatePayment() wrapped in kDebugMode guard
- [x] Unified auth via ApiService

### B3: Client Credential Cleanup
- [x] app_config.dart: adminPassword, adminAuthCode, operatorDefaultPassword -> String.fromEnvironment with empty Release defaults
- [x] login_screen.dart: phone pre-fill only in kDebugMode
- [x] auth_provider.dart: all inline credentials replaced with AppConfig refs

### B4: Inventory Persistence
- [x] InventoryNotifier: _loadFromStorage() (API -> local cache -> static seed)
- [x] _saveToLocal() + _syncStockToApi() after each change
- [x] Deleted _buildSampleTransactions() (TX-001~TX-005)
- [x] Added API endpoints: inventoryItem, inventoryStock, inventoryTransactions

### B5: Review Backend Sync
- [x] ReviewService -> GET /api/reviews + POST /api/reviews
- [x] Deleted _getMockReviews() (REVIEW-MOCK-001~005)
- [x] Empty-state display when no reviews

### B6: Push Notification Foundation
- [x] _startPolling() every 2 min -> /api/notifications
- [x] Persists last 200 notifications to SharedPreferences
- [x] Debug-only mock device token (kDebugMode guard)

---

## P1 - Next Steps

### Order Status WebSocket
- [ ] Connect to ws://.../api/ws?token=...
- [ ] Handle order lifecycle push: created -> paid -> shipped -> delivered
- [ ] Reconnect with exponential backoff

### Cart Cloud Sync on Login
- [ ] Full cart sync after login (replace partial implementation)
- [ ] Conflict resolution: prefer server state

### AI Image Upload
- [ ] GeminiImageService -> backend /api/ai/analyze-image proxy
- [ ] Upload progress indicator
- [ ] Handle backend 30s timeout gracefully

---

## P2 - Backlog

- [ ] Favorites real-time sync
- [ ] Product search history persistence
- [ ] FCM/APNs push (requires app signing, Phase 3)
