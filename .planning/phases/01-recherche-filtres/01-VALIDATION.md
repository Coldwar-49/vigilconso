---
phase: 1
slug: recherche-filtres
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK built-in, flutter_lints 5.0.0) |
| **Config file** | `analysis_options.yaml` (extends flutter_lints) |
| **Quick run command** | `flutter test test/services_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

> Note: `test/widget_test.dart` has a fake counter-app test that fails. Use `flutter test test/services_test.dart` for per-task quick runs until Wave 0 replaces it.

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/services_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | SRCH-01 | — | Query sanitized before URL injection | integration | Manuel (API live) | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 2 | SRCH-04 | T-1-01 | N/A | unit | `flutter test test/filter_logic_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 2 | SRCH-05 | — | N/A | unit | `flutter test test/filter_logic_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-03 | 02 | 2 | SRCH-06 | — | N/A | unit | `flutter test test/filter_logic_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-04 | 02 | 2 | SRCH-08 | — | N/A | unit | `flutter test test/filter_logic_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 3 | SRCH-02 | T-1-02 | Debounce 300ms limits API calls | widget | `flutter test test/search_screen_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 3 | SRCH-03 | — | N/A | unit | `flutter test test/search_history_service_test.dart` | ❌ W0 | ⬜ pending |
| 1-04-01 | 04 | 4 | SRCH-07 | — | N/A (non-sensitive data) | unit | `flutter test test/read_status_service_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/search_history_service_test.dart` — stubs for SRCH-03 (addToHistory, getHistory, clearHistory)
- [ ] `test/read_status_service_test.dart` — stubs for SRCH-07 (markAsRead, isRead, persistance entre sessions)
- [ ] `test/filter_logic_test.dart` — stubs for SRCH-04/05/06/08 (logique client-side de filtrage et tri)
- [ ] `test/search_screen_test.dart` — stubs for SRCH-02 (apparition des suggestions avec SearchService mock)

> Existing infrastructure: `flutter_test` already present. No new test framework installation needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recherche "Nutella" retourne résultats toutes catégories | SRCH-01 | Requiert réseau live vers API gouvernementale | Taper "Nutella" dans SearchScreen, vérifier résultats < 3s de toutes catégories |
| Suggestions apparaissent en temps réel | SRCH-02 | Comportement visuel temporel difficile à automatiser fiablement | Taper "Nut" dans SearchScreen, vérifier apparition de suggestions après 300ms |
| Historique cliquable recharge les résultats | SRCH-03 | Nécessite navigation entre écrans | Effectuer 3 recherches, fermer SearchScreen, rouvrir, cliquer historique |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
