# Agent C - Testing & Security Roadmap

> Last updated: 2026-03-25

---

## Completed

### C1: Backend pytest Infrastructure
- [x] conftest.py shared fixtures (client, auth tokens, clean_state autouse)
- [x] Adapted to modular backend (store module imports)
- [x] Adapted to SMS code change (888888)
- [x] Adapted to JWT stateless logout behavior
- [x] 57 -> 78 test cases all passing
- [x] Coverage: 10 of 13 routers (health, auth, products, cart, orders, misc, shops, notifications, admin, upload)

### C2: Flutter Widget Tests
- [x] LoginScreen 5 tests (pump vs pumpAndSettle)
- [x] ProductListScreen 5 tests (FadeSlideTransition timer fix)
- [x] CartScreen 5 tests (Riverpod integration)
- [x] CheckoutScreen 5 tests (FlutterError.onError in test body)
- [x] OrderListScreen 5 tests (TabBar + initialTab)
- [x] All 25 tests passing

### C3: CI Security Scanning
- [x] Credential leak detection (grep: sk-*, AIza*, AKIA*, ghp_*, PEM)
- [x] .env / secrets.dart accidental commit check
- [x] Python SAST (bandit)
- [x] Dependency audit (pip-audit)
- [x] .gitignore completeness check
- [x] Security config audit (DEBUG=True detection)
- [x] deploy-backend now depends on security-scan passing

---

## P0 - Next Steps (ETA: 1-2 days)

### Backend Coverage Increase (target >=80% line)
- [ ] WebSocket tests (routers/ws.py): connect, token auth, message push
- [ ] File upload tests (multipart, type/size validation)
- [ ] AI proxy tests (routers/ai.py): image analysis endpoint mock
- [ ] Boundary conditions: oversized strings, injection, concurrent requests

### Integration Test Expansion
- [ ] Full flow: login -> browse -> cart -> checkout -> pay
- [ ] Admin flow: login -> product manage -> ship order
- [ ] AI fallback chain: DashScope -> offline response

---

## P1 - Important (ETA: 3-5 days)

- [ ] Property-based testing (hypothesis): order amount, stock atomicity
- [ ] Load testing baseline (locust/k6): /api/products P95, /api/orders QPS
- [ ] DAST (OWASP ZAP): SQL injection, XSS, CORS, auth bypass

---

## P2 - Backlog

- [ ] Visual regression testing (golden_toolkit)
- [ ] Accessibility testing (Flutter Semantics)
- [ ] Supply chain security (Dependabot, pub license audit)
- [ ] Coverage dashboard (pytest-cov -> Codecov, flutter --coverage)

---

## Metrics

| Metric | Current | Target |
|---|---|---|
| Backend test cases | 78 | 100+ |
| Frontend widget tests | 25 | 40+ |
| Backend coverage | ~65% (est.) | >=80% |
| Frontend coverage | ~20% (est.) | >=60% |
| CI security checks | 6 | 10+ |
