---
phase: 1
status: findings
files_reviewed: 12
findings:
  critical: 3
  warning: 7
  info: 3
  total: 13
---

# Code Review: Phase 1 — Recherche & Filtres

## Summary

12 source files reviewed at standard depth covering search, filtering, read-status tracking, history,
and the detail page. The codebase is structurally sound and the architecture (FilterState value-object,
static filter helpers, separated services) is clean. Three critical issues were found: a cache
key collision that silently returns stale/wrong data when date filters are active, read-status
filtering executed on an uninitialised (empty) `_readIds` set on first run, and raw exception
strings exposed to end-users in `rappel_screen.dart`. Seven warnings address subtle logic gaps,
a missing `mounted` guard, an unbounded storage list, and a filter-reset dead path.

---

## Critical Issues

### CR-001 [CRITICAL] Cache key ignores dateFrom/dateTo — wrong cached data returned (rappel_service.dart:33)

**Issue:** `fetchRappels` derives its cache key from `categoryKey` alone
(`'$_cacheKey$categoryKey'`). If a first call is made for `categoryKey='all'` with no date
filter and the results are cached, a subsequent call with `dateFrom='2025-01-01'` and the same
`categoryKey='all'` will find a valid cache entry (the 5-minute window) and return it —
ignoring the date filter entirely. The reverse is also true: a narrow-date cache is returned
for a broad query.

The guard `if (cached != null && searchQuery.isEmpty)` on line 39 prevents cache use when a
text query is active, but date-filter-only queries (triggered when the user picks "7 jours"
and the search box is empty) fall straight through to the cache hit.

**Impact:** "7 jours" / "30 jours" / "90 jours" / custom-date filters silently return
unfiltered results whenever a non-filtered result set is already cached. The user sees no
error and has no indication the date filter was ignored.

**Fix:**
```dart
// Include date parameters in the cache key
final cacheKey = '$_cacheKey${categoryKey}_${dateFrom ?? ''}_${dateTo ?? ''}';
final lastFetchKey = '$_lastFetchKey${categoryKey}_${dateFrom ?? ''}_${dateTo ?? ''}';
```

---

### CR-002 [CRITICAL] `_readIds` is empty on first filter application — read/unread filter always wrong (search_screen.dart:97-232)

**Issue:** `_loadReadStatus()` is never called in `initState()`. It is called only inside
`_performSearch()` (line 311) and `_applyFiltersAndSearch()` (line 232) *after* the results
are already filtered and displayed. If the user has a persisted `readFilter: 'unread'` (loaded
by `_loadPersistedFilters()` on line 117), the very first search applies
`SearchScreen.applyReadFilter('unread', results, {})` against an empty `_readIds` set, so
every result appears as "unread" and nothing is actually filtered out. The badge is also
computed against the stale empty set.

**Impact:** The "Non lus" and "Lus" filter options produce incorrect results on every app
launch until at least one search has completed. Users who rely on read-status filtering see
wrong counts and wrong filtered lists.

**Fix:**
```dart
@override
void initState() {
  super.initState();
  _staggerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  _loadPersistedFilters();
  _loadHistory();
  _loadReadStatus(); // ADD THIS — must be called before first search
  _searchFocusNode.addListener(() { ... });
  if (widget.initialQuery.isNotEmpty) {
    _searchController.text = widget.initialQuery;
    _performSearch(widget.initialQuery);
  }
}
```

---

### CR-003 [CRITICAL] Raw exception toString() exposed to users (rappel_screen.dart:103)

**Issue:** In `_loadRappels`, the catch block builds the error message as
`'Erreur: $e'` (line 103) and stores it in `_errorMessage`. That string is rendered
verbatim in `_buildErrorState()` at line 615 via `Text(_errorMessage!, ...)`. Dart exception
`.toString()` can include stack fragments, socket addresses, HTTP response bodies, or
internal file paths — all visible to the end user.

**Impact:** Information leakage. Users with network-level errors may see raw socket
addresses or internal API URLs. This is also an inconsistent UX compared to the identical
code path in `search_screen.dart` which always shows a fixed user-friendly message.

**Fix:**
```dart
} catch (e) {
  if (!mounted) return;
  setState(() {
    _isLoading = false;
    // Do NOT interpolate e — use a fixed user-facing message
    _errorMessage = 'Impossible de charger les données. Vérifiez votre connexion.';
  });
}
```
Log the original exception via `debugPrint` separately if needed for diagnostics.

---

## Warnings

### WR-001 [WARNING] Filter-reset with empty search box does not refresh results (search_screen.dart:256-265)

**Issue:** The `onReset` callback in `_openFilterPanel` only triggers a new search when
`_searchController.text.isNotEmpty` (line 260). If the user had active filters applied to a
search, then clears all text, then resets filters, the old filtered results remain displayed —
`_filteredResults` is stale. The read-status filter chip is removed from the chips row but
the result list is not re-filtered.

**Fix:**
```dart
onReset: () async {
  setState(() => _activeFilters = FilterState.empty);
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_activeFiltersKey);
  if (_searchController.text.isNotEmpty) {
    _performSearch(_searchController.text);
  } else if (_hasSearched) {
    // Re-apply with cleared filters so the displayed list is refreshed
    _applyFiltersAndSearch();
  }
},
```

---

### WR-002 [WARNING] `applyReadFilter` applies client-side over server-returned data before `_readIds` is refreshed (search_screen.dart:223-224 / 302-304)

**Issue:** Both `_performSearch` and `_applyFiltersAndSearch` apply
`SearchScreen.applyReadFilter` to the results *before* calling `_loadReadStatus()` (lines
232 and 311). The `_readIds` set used at filter time is always one search cycle stale. A
rappel marked as read during this session (by tapping it) is updated in local `_readIds`
state only (line 641: `setState(() => _readIds = {..._readIds, id})`), but the next search
will re-call `_loadReadStatus()` asynchronously, meaning there is a window where the
displayed read-filter results are based on the pre-update set.

This compounds CR-002: even after the first load, the sequence "apply filter → tap rappel →
back → trigger filter" may briefly show stale state.

**Fix:** Await `_loadReadStatus()` before filtering:
```dart
// In both _performSearch and _applyFiltersAndSearch, before applying filters:
await _loadReadStatus();
var results = List<dynamic>.from(result['results'] ?? []);
results = SearchScreen.applyReadFilter(_activeFilters.readFilter, results, _readIds);
```

---

### WR-003 [WARNING] `FilterState.fromJson` does not validate `readFilter` value (filter_panel.dart:91)

**Issue:** `fromJson` restores `readFilter` directly from the stored string without
validation: `readFilter: (json['readFilter'] as String?) ?? 'all'`. If the stored value is
anything other than `'all'`, `'unread'`, or `'read'` (e.g. corrupted prefs, future schema
change), `applyReadFilter` enters the `isRead` branch silently and shows only read items,
which is wrong.

**Fix:**
```dart
factory FilterState.fromJson(Map<String, dynamic> json) {
  const validReadFilters = {'all', 'unread', 'read'};
  final rf = (json['readFilter'] as String?) ?? 'all';
  return FilterState(
    riskLevels: Set<String>.from((json['riskLevels'] as List? ?? [])),
    dateDays: json['dateDays'] as int?,
    brandKeyword: (json['brandKeyword'] as String?) ?? '',
    readFilter: validReadFilters.contains(rf) ? rf : 'all',
  );
}
```

---

### WR-004 [WARNING] `home_screen.dart` `_countNewAlerts` uses `DateTime.tryParse` — misses `dd/MM/yyyy` dates (home_screen.dart:96-97)

**Issue:** `_countNewAlerts` parses dates with `DateTime.tryParse(dateStr)` (line 96).
`DateTime.tryParse` only handles ISO 8601 format (`yyyy-MM-dd`). The API occasionally
returns dates in `dd/MM/yyyy` format (which is why `RappelService.parseDate` exists with a
two-format parser). For any rappel with a non-ISO date string, `_countNewAlerts` returns
`null` and that rappel is not counted as new, silently under-counting the badge.

**Fix:**
```dart
// Replace DateTime.tryParse with RappelService.parseDate
import 'package:vigiconso/services/rappel_service.dart';

Future<int> _countNewAlerts(List<dynamic> rappels) async {
  final prefs = await SharedPreferences.getInstance();
  final lastSeenStr = prefs.getString('last_seen_alert_date');
  if (lastSeenStr == null) return 0;
  final lastSeen = DateTime.tryParse(lastSeenStr);
  if (lastSeen == null) return 0;
  int count = 0;
  for (final r in rappels) {
    final dateStr = r['date_publication'] ?? '';
    final date = RappelService.parseDate(dateStr); // handles both formats
    if (date != null && date.isAfter(lastSeen)) count++;
  }
  return count;
}
```

---

### WR-005 [WARNING] `ReadStatusService` storage grows unboundedly (read_status_service.dart:25-33)

**Issue:** `markAsRead` appends IDs to a `SharedPreferences` string list with no upper
bound. Over months of use, the list can grow to thousands of entries. `SharedPreferences`
stores the entire list as a single serialised blob; every read/write loads and serialises the
full set. Large sets will cause measurable latency on `getReadIds`, `getUnreadCount`, and
`markAsRead`.

**Fix:** Implement a sliding window or TTL-based eviction. A pragmatic approach is to
pair each ID with the date it was read and evict entries older than, e.g., 90 days when
`markAsRead` is called:
```dart
// Alternative: cap the stored list to a maximum size (e.g. 500 most recent)
static const int _maxReadIds = 500;

static Future<void> markAsRead(String id) async {
  if (id.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_readKey) ?? [];
  if (raw.contains(id)) return;
  raw.insert(0, id); // most recent first
  if (raw.length > _maxReadIds) raw.removeLast();
  await prefs.setStringList(_readKey, raw);
}
```

---

### WR-006 [WARNING] `rappel_screen.dart` `_applyYearFilter` naming is misleading — no year filter applied (rappel_screen.dart:73-78)

**Issue:** `_applyYearFilter()` is named as if it applies a year-based filter, but its
implementation only copies `_rappels` verbatim into `_filteredRappels` and resets the page
counter. There is no year-filtering logic. This misleads anyone maintaining the code about
what the method does and creates dead expectation — tests expecting year filtering will never
find it here.

**Fix:** Rename to `_resetFilter()` or `_applyLocalFilter()` and document it accurately,
or remove and inline the two-line body into `_toggleSortOrder`.

---

### WR-007 [WARNING] `_customDateChip` uses `BuildContext` across `async` gap without `mounted` check (filter_panel.dart:307-319)

**Issue:** `_customDateChip`'s `onSelected` is an `async` callback that calls
`showDateRangePicker` and then calls `setState` after the `await` (line 313-318). There is
no `if (!mounted) return;` guard before `setState`. If the `FilterPanel` is dismissed while
the date picker is open (e.g. back gesture), `setState` is called on a disposed widget,
triggering a `setState() called after dispose()` assertion in debug and a no-op in release.

**Fix:**
```dart
onSelected: (_) async {
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );
  if (!mounted) return; // ADD THIS
  if (range != null) {
    setState(() {
      _customDateRange = range;
      _dateDays = null;
    });
  }
},
```

---

## Info

### IN-001 [INFO] Duplicated image-extraction and proxy logic across three files (search_screen.dart, rappel_screen.dart, home_screen.dart)

**Issue:** `_extractFirstImageUrl` and `_proxiedUrl` are copy-pasted identically (with
minor whitespace differences) in `search_screen.dart` (lines 421-445), `rappel_screen.dart`
(lines 129-153), and `home_screen.dart` (lines 361-380). Any bug fix or proxy URL change
must be applied in three places.

**Fix:** Extract both helpers into a shared utility file, e.g.
`lib/utils/image_utils.dart`, and import them in the three screens.

---

### IN-002 [INFO] `debugPrint` calls in release-visible paths (rappel_details_page.dart:344, rappel_service.dart:110-111)

**Issue:** `debugPrint('Erreur image: $error')` in `rappel_details_page.dart` line 344 and
`debugPrint('RappelService error: $e')` / `debugPrint('fetchLatestRappels error: $e')` in
`rappel_service.dart` lines 110-111 and 172 will output to the console in both debug and
profile builds. `debugPrint` is not stripped in release; only `assert` and `kDebugMode`
guards are. These calls may leak stack traces and URLs in profile-mode performance testing
and some development device consoles.

**Fix:** Wrap in `kDebugMode` from `package:flutter/foundation.dart`:
```dart
if (kDebugMode) debugPrint('RappelService error: $e');
```
Or use a structured logger.

---

### IN-003 [INFO] `search_screen_test.dart` contains only skipped tests — zero coverage of widget behaviour (search_screen_test.dart:5-13)

**Issue:** The `search_screen_test.dart` file contains three tests that are all unconditionally
skipped with `skip: 'Nécessite widget test avec mock HTTP — Phase 6'`. The file provides no
actual test coverage; it exists only as a placeholder. A future reader may assume debounce
and suggestion behaviour is tested when it is not.

**Fix:** Either remove the file until Phase 6 is implemented, or annotate clearly in the
group description that these are forward declarations pending implementation, and ensure the
CI pipeline reports them as pending rather than passing.

---

_Reviewed: 2026-06-18T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
