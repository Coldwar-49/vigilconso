import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';
import 'package:vigiconso/services/rappel_service.dart';
import 'package:vigiconso/services/search_history_service.dart';
import 'package:vigiconso/widgets/filter_panel.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  // ── Méthodes statiques publiques (accessibles depuis les tests) ───────────

  /// Filtre client-side par niveau de risque (OR logic).
  /// riskLevels: {'grave', 'modéré', 'faible'} — vide = pas de filtre.
  static List<dynamic> applyRiskFilter(
      Set<String> riskLevels, List<dynamic> results) {
    if (riskLevels.isEmpty) return results;
    return results.where((r) {
      final risque = (r['risques_encourus'] ?? '').toString().toLowerCase();
      for (final level in riskLevels) {
        if (level == 'grave' &&
            (risque.contains('grave') ||
                risque.contains('sérieux') ||
                risque.contains('serieux') ||
                risque.contains('élevé') ||
                risque.contains('eleve'))) {
          return true;
        }
        if (level == 'modéré' &&
            (risque.contains('modéré') ||
                risque.contains('moderé') ||
                risque.contains('moyen'))) {
          return true;
        }
        if (level == 'faible' &&
            (risque.contains('faible') ||
                risque.contains('bénin') ||
                risque.contains('benin'))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Filtre client-side par marque (case-insensitive contains sur marque_produit).
  static List<dynamic> applyBrandFilter(
      String keyword, List<dynamic> results) {
    if (keyword.isEmpty) return results;
    final kw = keyword.toLowerCase();
    return results.where((r) {
      final brand =
          (r['marque_produit'] ?? r['nom_marque'] ?? '').toString().toLowerCase();
      return brand.contains(kw);
    }).toList();
  }

  /// Filtre client-side par statut lu/non-lu.
  /// readFilter: 'all' = pas de filtre, 'unread' = non lus, 'read' = lus.
  /// readIds: Set des IDs de rappels déjà lus.
  static List<dynamic> applyReadFilter(
      String readFilter, List<dynamic> results, Set<String> readIds) {
    if (readFilter == 'all') return results;
    return results.where((r) {
      final id = r['reference_fiche']?.toString() ??
          r['libelle']?.toString() ??
          r['numero_fiche']?.toString() ??
          '';
      final isRead = id.isNotEmpty && readIds.contains(id);
      return readFilter == 'unread' ? !isRead : isRead;
    }).toList();
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  List<dynamic> _allResults = [];
  List<dynamic> _filteredResults = [];
  bool _isNewestFirst = true;
  late AnimationController _staggerController;

  // ── Filtres ───────────────────────────────────────────────────────────────
  static const String _activeFiltersKey = 'active_filters';
  FilterState _activeFilters = FilterState.empty;
  // ignore: prefer_final_fields — Plan 4 reassigns via setState(() => _readIds = ids)
  Set<String> _readIds = {};

  // ── Historique + autocomplétion ───────────────────────────────────────────
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _isFetchingSuggestions = false;
  List<String> _searchHistory = [];
  bool _showingHistory = false;
  bool _confirmingClearHistory = false;
  Timer? _clearConfirmTimer;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadPersistedFilters();
    _loadHistory();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _showingHistory = true);
      }
    });
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _clearConfirmTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ── Persistance filtres ───────────────────────────────────────────────────

  Future<void> _loadPersistedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeFiltersKey);
    if (raw != null && mounted) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        setState(() => _activeFilters = FilterState.fromJson(json));
      } catch (_) {
        // Filtre corrompu — ignorer et repartir avec l'état vide (T-1-13)
      }
    }
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.getHistory();
    if (mounted) setState(() => _searchHistory = history);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) {
      setState(() {
        _suggestions = [];
        _showingHistory = value.isEmpty;
      });
      return;
    }
    setState(() => _showingHistory = false);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String prefix) async {
    setState(() => _isFetchingSuggestions = true);
    final results = await RappelService.fetchSuggestions(prefix);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isFetchingSuggestions = false;
    });
  }

  Future<void> _applyFiltersAndSearch() async {
    final query = _searchController.text.trim().replaceAll('"', '');
    if (query.isEmpty && !_activeFilters.hasActiveFilters) return;

    // Persister les filtres actifs (per CONTEXT.md locked decision)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeFiltersKey, jsonEncode(_activeFilters.toJson()));

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });
    try {
      final result = await RappelService.fetchRappels(
        categoryKey: 'all',
        searchQuery: query,
        dateFrom: _activeFilters.apiDateFrom,
        dateTo: _activeFilters.apiDateTo,
        newestFirst: _isNewestFirst,
      );
      if (!mounted) return;
      if (result.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'];
        });
        return;
      }
      var results = List<dynamic>.from(result['results'] ?? []);
      // Filtres client-side
      results = SearchScreen.applyRiskFilter(_activeFilters.riskLevels, results);
      results = SearchScreen.applyBrandFilter(_activeFilters.brandKeyword, results);
      results =
          SearchScreen.applyReadFilter(_activeFilters.readFilter, results, _readIds);
      setState(() {
        _allResults = List<dynamic>.from(result['results'] ?? []);
        _filteredResults = results;
        _hasSearched = true;
        _isLoading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Impossible de charger les résultats. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  // ── Panel de filtres ──────────────────────────────────────────────────────

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterPanel(
        initialState: _activeFilters,
        onApply: (newState) {
          setState(() => _activeFilters = newState);
          _applyFiltersAndSearch();
        },
        onReset: () async {
          setState(() => _activeFilters = FilterState.empty);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_activeFiltersKey);
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
      ),
    );
  }

  // ── Recherche principale ──────────────────────────────────────────────────

  Future<void> _performSearch(String query) async {
    final q = query.trim().replaceAll('"', ''); // sanitize avant injection URL (T-1-01)
    if (q.isEmpty) return;

    await SearchHistoryService.addToHistory(q);
    _loadHistory();
    setState(() {
      _suggestions = [];
      _showingHistory = false;
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });
    try {
      final result = await RappelService.fetchRappels(
        categoryKey: 'all',
        searchQuery: q,
        dateFrom: _activeFilters.apiDateFrom,
        dateTo: _activeFilters.apiDateTo,
        newestFirst: _isNewestFirst,
      );
      if (!mounted) return;
      if (result.containsKey('error')) {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'];
        });
        return;
      }
      var results = List<dynamic>.from(result['results'] ?? []);
      // Filtres client-side
      results = SearchScreen.applyRiskFilter(_activeFilters.riskLevels, results);
      results = SearchScreen.applyBrandFilter(_activeFilters.brandKeyword, results);
      results =
          SearchScreen.applyReadFilter(_activeFilters.readFilter, results, _readIds);
      setState(() {
        _allResults = List<dynamic>.from(result['results'] ?? []);
        _filteredResults = results;
        _isLoading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Impossible de charger les résultats. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  void _toggleSort() {
    setState(() {
      _isNewestFirst = !_isNewestFirst;
      _filteredResults.sort((a, b) {
        final da =
            RappelService.parseDate(a['date_publication'] ?? '') ?? DateTime(1900);
        final db =
            RappelService.parseDate(b['date_publication'] ?? '') ?? DateTime(1900);
        return _isNewestFirst ? db.compareTo(da) : da.compareTo(db);
      });
    });
  }

  void _openDetails(dynamic rappel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RappelDetailsPage(rappel: rappel)),
    );
  }

  // ── Chips actifs ──────────────────────────────────────────────────────────

  List<Widget> _buildActiveFilterChips() {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    for (final level in _activeFilters.riskLevels) {
      final label = level == 'grave'
          ? 'Grave'
          : level == 'modéré'
              ? 'Modéré'
              : 'Faible';
      chips.add(_activeChip(label, cs, onRemove: () {
        final newLevels = Set<String>.from(_activeFilters.riskLevels)
          ..remove(level);
        setState(() => _activeFilters = _activeFilters.copyWith(riskLevels: newLevels));
        _applyFiltersAndSearch();
      }));
    }

    if (_activeFilters.customDateRange != null) {
      final r = _activeFilters.customDateRange!;
      final label =
          '${r.start.day.toString().padLeft(2, '0')}/${r.start.month.toString().padLeft(2, '0')} – '
          '${r.end.day.toString().padLeft(2, '0')}/${r.end.month.toString().padLeft(2, '0')}';
      chips.add(_activeChip(label, cs, onRemove: () {
        setState(() => _activeFilters =
            _activeFilters.copyWith(clearCustomDateRange: true));
        _applyFiltersAndSearch();
      }));
    } else if (_activeFilters.dateDays != null) {
      chips.add(_activeChip('${_activeFilters.dateDays} jours', cs, onRemove: () {
        setState(() =>
            _activeFilters = _activeFilters.copyWith(clearDateDays: true));
        _applyFiltersAndSearch();
      }));
    }

    if (_activeFilters.brandKeyword.isNotEmpty) {
      chips.add(_activeChip(_activeFilters.brandKeyword, cs, onRemove: () {
        setState(() =>
            _activeFilters = _activeFilters.copyWith(brandKeyword: ''));
        _applyFiltersAndSearch();
      }));
    }

    if (_activeFilters.readFilter != 'all') {
      final label =
          _activeFilters.readFilter == 'unread' ? 'Non lus' : 'Lus';
      chips.add(_activeChip(label, cs, onRemove: () {
        setState(() =>
            _activeFilters = _activeFilters.copyWith(readFilter: 'all'));
        _applyFiltersAndSearch();
      }));
    }

    return chips;
  }

  Widget _activeChip(String label, ColorScheme cs,
      {required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        backgroundColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onPrimaryContainer),
        deleteIconColor: cs.onPrimaryContainer,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Extrait la première URL valide depuis liens_vers_les_images (String ou List)
  String? _extractFirstImageUrl(dynamic rappel) {
    final dynamic imagesData = rappel['liens_vers_les_images'];
    if (imagesData == null) return null;

    if (imagesData is String && imagesData.isNotEmpty) {
      final rawUrls = imagesData.split(RegExp(r'[,;|\s]+'));
      for (var url in rawUrls) {
        final trimmed = url.trim().replaceAll('"', '').replaceAll("'", '');
        if (trimmed.startsWith('http')) return trimmed;
      }
    } else if (imagesData is List) {
      for (final item in imagesData) {
        if (item is String && item.trim().startsWith('http')) {
          return item.trim();
        }
      }
    }
    return null;
  }

  /// Proxy wsrv.nl pour corriger le chargement des images sur toutes les plateformes
  String _proxiedUrl(String url) {
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }

  /// Retourne "il y a X jours/heures/minutes" ou la date formatée
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Couleur selon le niveau de risque
  Color _riskColor(String? risque, ColorScheme cs) {
    if (risque == null) return cs.surfaceContainerHighest;
    final r = risque.toLowerCase();
    if (r.contains('grave') ||
        r.contains('sérieux') ||
        r.contains('serieux') ||
        r.contains('élevé')) {
      return const Color(0xFFB71C1C);
    }
    if (r.contains('modéré') || r.contains('moyen')) return const Color(0xFFE65100);
    if (r.contains('faible') || r.contains('bénin') || r.contains('benin')) {
      return const Color(0xFF1B5E20);
    }
    return cs.primary;
  }

  Widget _imagePlaceholderSquare(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.warning_amber_rounded,
          size: 32,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildNetworkImageWithFallback(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext)? errorBuilder,
  }) {
    final imageUrl = _proxiedUrl(url);
    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (errorBuilder != null) return errorBuilder(context);
        final cs = Theme.of(context).colorScheme;
        return Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 22, color: cs.onSurfaceVariant),
                const SizedBox(height: 2),
                Text('Image indisponible',
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.surfaceContainerHighest;
    final textColor = selected ? cs.onPrimary : cs.onSurface;
    final iconColor = selected ? cs.onPrimary : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte style Google News — identique à rappel_screen.dart._buildRappelCard
  Widget _buildRappelCard(dynamic rappel, int index) {
    final title =
        rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand =
        (rappel['marque_produit'] ?? rappel['nom_marque'] ?? '').toString();
    final categorie = (rappel['categorie_produit'] ?? '').toString();
    // Champ correct selon RESEARCH.md Pitfall 4 — vérification live API 2026-06-16
    final risque = rappel['risques_encourus']?.toString() ??
        rappel['risque_produit']?.toString();
    final imageUrl = _extractFirstImageUrl(rappel);
    final cs = Theme.of(context).colorScheme;

    DateTime? parsedDate;
    bool isNew = false;
    // isRead — Plan 4: connecter à ReadStatusService.isRead(rappelId)
    // Plan 1-2: hardcodé false → semantics label inclut toujours ', non lu'
    String timeLabel = '';
    if (rappel['date_publication'] != null) {
      try {
        parsedDate =
            RappelService.parseDate(rappel['date_publication'].toString());
        if (parsedDate != null) {
          timeLabel = _timeAgo(parsedDate);
          isNew = DateTime.now().difference(parsedDate).inDays <= 7;
        }
      } catch (_) {}
    }

    final riskColor = _riskColor(risque, cs);

    final delay = (index * 0.05).clamp(0.0, 0.7);
    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          delay,
          (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );
    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          delay,
          (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Semantics(
            label: '$title, $brand, $timeLabel, non lu',
            child: InkWell(
              onTap: () => _openDetails(rappel),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Contenu texte (gauche) ──────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges en haut
                          Row(
                            children: [
                              if (isNew)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'NOUVEAU',
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              if (categorie.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    categorie,
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Titre principal
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Marque + date
                          Row(
                            children: [
                              if (brand.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    brand,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeLabel.isNotEmpty)
                                  Text(
                                    '  ·  ',
                                    style: TextStyle(
                                        color: cs.outlineVariant, fontSize: 12),
                                  ),
                              ],
                              if (timeLabel.isNotEmpty)
                                Text(
                                  timeLabel,
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant, fontSize: 12),
                                ),
                            ],
                          ),
                          // Puce de risque
                          if (risque != null && risque.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: riskColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    risque,
                                    style: TextStyle(
                                      color: riskColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Image miniature (droite) ────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: imageUrl != null
                            ? _buildNetworkImageWithFallback(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx) =>
                                    _imagePlaceholderSquare(cs),
                              )
                            : _imagePlaceholderSquare(cs),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardShimmer() {
    final cs = Theme.of(context).colorScheme;
    final shimmerColor = cs.primaryContainer.withValues(alpha: 0.35);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: 70,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(width: 90, height: 90, color: shimmerColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          hintText: 'Rechercher un produit, une marque...',
          leading: const Icon(Icons.search),
          trailing: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Effacer',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _allResults = [];
                    _filteredResults = [];
                    _hasSearched = false;
                  });
                },
              ),
            // Bouton filtres avec badge point bleu si filtres actifs
            Stack(children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtres',
                onPressed: _openFilterPanel,
              ),
              if (_activeFilters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ]),
          ],
          onChanged: (value) {
            setState(() {}); // rebuild pour clear button
            _onSearchChanged(value);
          },
          onSubmitted: _performSearch,
        ),
        automaticallyImplyLeading: true,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    final mainContent = _resolveMainContent(cs);
    if (_suggestions.isEmpty && !_isFetchingSuggestions) return mainContent;

    return Stack(children: [
      mainContent,
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 320),
            color: cs.surface,
            child: _isFetchingSuggestions
                ? const LinearProgressIndicator()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.search),
                      title:
                          Text(_suggestions[i], style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        _searchController.text = _suggestions[i];
                        _performSearch(_suggestions[i]);
                        setState(() => _suggestions = []);
                      },
                    ),
                  ),
          ),
        ),
      ),
    ]);
  }

  Widget _resolveMainContent(ColorScheme cs) {
    if (_isLoading) return _buildShimmerList();
    if (_errorMessage != null) return _buildErrorState(cs);
    if (!_hasSearched || _showingHistory) return _buildIdleState(cs);
    if (_filteredResults.isEmpty) return _buildEmptyState(cs);
    return _buildResultsList(cs);
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (_, __) => _buildCardShimmer(),
    );
  }

  Widget _buildIdleState(ColorScheme cs) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Aucune recherche récente',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Vos recherches apparaîtront ici.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(children: [
            Icon(Icons.history, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
                child: Text('Recherches récentes',
                    style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500))),
            _confirmingClearHistory
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(
                      onPressed: () async {
                        _clearConfirmTimer?.cancel();
                        await SearchHistoryService.clearHistory();
                        if (mounted) {
                          setState(() {
                            _searchHistory = [];
                            _confirmingClearHistory = false;
                          });
                        }
                      },
                      child: Text('Confirmer ?',
                          style: TextStyle(color: cs.error, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearConfirmTimer?.cancel();
                        setState(() => _confirmingClearHistory = false);
                      },
                      child: const Text('Annuler', style: TextStyle(fontSize: 12)),
                    ),
                  ])
                : TextButton(
                    onPressed: () {
                      setState(() => _confirmingClearHistory = true);
                      _clearConfirmTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted) setState(() => _confirmingClearHistory = false);
                      });
                    },
                    child: const Text("Effacer l'historique",
                        style: TextStyle(fontSize: 12)),
                  ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (_, i) {
              final query = _searchHistory[i];
              return ListTile(
                leading: Icon(Icons.history, color: cs.onSurfaceVariant),
                title: Text(query, style: const TextStyle(fontSize: 15)),
                trailing: IconButton(
                  icon: Icon(Icons.north_west, size: 16, color: cs.onSurfaceVariant),
                  tooltip: 'Copier dans la recherche',
                  onPressed: () {
                    _searchController.text = query;
                    _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: query.length));
                    setState(() {});
                  },
                ),
                onTap: () => _performSearch(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun rappel ne correspond à votre recherche. Essayez d\'autres mots-clés ou supprimez des filtres.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: cs.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les résultats. Vérifiez votre connexion et réessayez.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () => _performSearch(_searchController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(ColorScheme cs) {
    final count = _filteredResults.length;
    final total = _allResults.length;
    final label = count == total
        ? (count == 1 ? '1 résultat' : '$count résultats')
        : '$count / $total résultats';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  _buildSortChip(
                    label: 'Récent',
                    icon: Icons.arrow_downward,
                    selected: _isNewestFirst,
                    onTap: () {
                      if (!_isNewestFirst) _toggleSort();
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildSortChip(
                    label: 'Ancien',
                    icon: Icons.arrow_upward,
                    selected: !_isNewestFirst,
                    onTap: () {
                      if (_isNewestFirst) _toggleSort();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Chips actifs sous la SearchBar (si filtres actifs)
        if (_activeFilters.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildActiveFilterChips()),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _filteredResults.length,
            itemBuilder: (_, i) => _buildRappelCard(_filteredResults[i], i),
          ),
        ),
      ],
    );
  }
}
