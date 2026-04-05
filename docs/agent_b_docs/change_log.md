# Agent B Change Log

> Reverse-chronological record of all frontend changes in huiyuyuan_app/lib/.
> Last updated: 2026-03-25

---

## [2026-02-27] Phase 2 - Full Frontend Data Integration (Complete)

### Static Analysis Result
| Metric | Result |
|---|---|
| dart analyze lib/ errors | **0** |
| dart analyze lib/ warnings | **0** |
| Info hints | 182 (all pre-existing prefer_const_constructors) |

### B6: Push Notification
- **push_service.dart**: Added _startPolling() (2min), _loadNotifications()/_saveNotifications() (max 200), kDebugMode guard for mock token

### B5: Review Backend Sync
- **review_service.dart**: Rewrote _getAllReviews() (API->cache->empty), deleted _getMockReviews() (5 hardcoded reviews), added addReview() API sync

### B4: Inventory Persistence
- **inventory_provider.dart**: Added _loadFromStorage(), _saveToLocal(), _syncStockToApi(), deleted _buildSampleTransactions() (TX-001~TX-005)
- New API endpoints in api_config.dart: inventory, inventoryItem, inventoryStock, inventoryTransactions

### B3: Credential Cleanup
- **app_config.dart**: adminPassword/adminAuthCode/operatorDefaultPassword -> String.fromEnvironment (empty in Release)
- **auth_provider.dart**: loginAdmin/loginOperator -> API-first with AppConfig fallback (not inline literals)
- **login_screen.dart**: phone pre-fill '18937766669' wrapped in kDebugMode

### B2: Payment Security
- **payment_screen.dart**: Removed direct Dio() + 'Bearer mock_token'; removed pollCount>=3 auto-success; uses ApiService auth

### B1 (7 screens): Mock Data Elimination
- **shop_radar.dart**: Deleted _loadMockData() (5 shops), added _loadShops() -> GET /api/shops
- **notification_screen.dart**: Deleted _generateSampleData() (6 items), init with [] + async _loadFromApi()
- **logistics_screen.dart**: StatelessWidget->StatefulWidget, added _fetchLogisticsFromApi() -> GET /api/orders/{id}/logistics
- **contact_service.dart** (new): ContactRecord model + API-first singleton
- **shop_detail_screen.dart**: Hardcoded contacts -> ContactService.getShopContacts()
- **operator_home.dart**: Hardcoded 4 shops -> ContactService.getRecentContacts(limit: 5)
- **browse_history_screen.dart**: "Product {id}" -> real name/price/material/image via _findProduct()
- **favorite_list_screen.dart**: Added image field -> Image.network + ClipRRect
