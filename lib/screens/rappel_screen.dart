import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';
import 'package:vigiconso/services/rappel_service.dart';
import 'package:vigiconso/utils/constants.dart';
import 'package:vigiconso/widgets/app_menu.dart';

class RappelListScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryTitle;
  final String initialSearch;

  const RappelListScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
    this.initialSearch = '',
  });

  @override
  State<RappelListScreen> createState() => _RappelListScreenState();
}

class _RappelListScreenState extends State<RappelListScreen>
    with TickerProviderStateMixin {
  bool _isNewestFirst = true;
  List<dynamic> _rappels = [];
  List<dynamic> _filteredRappels = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = AppConstants.pageSize;
  String? _errorMessage;

  // Contrôleur d'animation pour l'apparition staggerée des cartes
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.initialSearch.isNotEmpty) {
      _searchQuery = widget.initialSearch;
      _searchController.text = widget.initialSearch;
    }
    _loadRappels();
  }

  void _toggleSortOrder() {
    setState(() {
      _isNewestFirst = !_isNewestFirst;
      _rappels.sort((a, b) {
        final dateA = RappelService.parseDate(a['date_publication'] ?? '') ?? DateTime(1900);
        final dateB = RappelService.parseDate(b['date_publication'] ?? '') ?? DateTime(1900);
        return _isNewestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });
      _applyYearFilter();
    });
  }

  void _applyYearFilter() {
    setState(() {
      _filteredRappels = List.from(_rappels);
      _currentPage = 0;
    });
  }

  Future<void> _loadRappels() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await RappelService.fetchRappels(
        categoryKey: widget.categoryKey,
        searchQuery: _searchQuery,
        newestFirst: _isNewestFirst,
      );
      if (!mounted) return;
      if (result.containsKey('error')) {
        setState(() { _isLoading = false; _errorMessage = result['error']; });
        return;
      }
      final results = List<dynamic>.from(result['results'] ?? []);
      setState(() {
        _rappels = results;
        _filteredRappels = List.from(results);
        _isLoading = false;
        _currentPage = 0;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Erreur: $e'; });
    }
  }

  void _openProductDetails(dynamic rappel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RappelDetailsPage(rappel: rappel),
      ),
    );
  }

  List<dynamic> get _paginatedRappels {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= _filteredRappels.length) {
      return [];
    }
    return _filteredRappels.sublist(
      startIndex,
      endIndex > _filteredRappels.length ? _filteredRappels.length : endIndex,
    );
  }

  /// Extrait la première URL valide depuis liens_vers_les_images (String ou List)
  String? _extractFirstImageUrl(dynamic rappel) {
    final dynamic imagesData = rappel['liens_vers_les_images'];
    if (imagesData == null) return null;

    if (imagesData is String && imagesData.isNotEmpty) {
      final rawUrls = imagesData.split(RegExp(r'[,;|\s]+'));
      for (var url in rawUrls) {
        final trimmed = url.trim().replaceAll('"', '').replaceAll("'", "");
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
              width: 24, height: 24,
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.image_not_supported_outlined, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(height: 2),
              Text('Image indisponible', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ]),
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
    if (r.contains('grave') || r.contains('sérieux') || r.contains('serieux') || r.contains('élevé')) {
      return const Color(0xFFB71C1C);
    }
    if (r.contains('modéré') || r.contains('moyen')) return const Color(0xFFE65100);
    if (r.contains('faible') || r.contains('bénin') || r.contains('benin')) return const Color(0xFF1B5E20);
    return cs.primary;
  }

  /// Carte style Google News — pleine largeur, texte à gauche, image à droite
  Widget _buildRappelCard(dynamic rappel, int index) {
    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand = (rappel['marque_produit'] ?? rappel['nom_marque'] ?? '').toString();
    final categorie = (rappel['categorie_produit'] ?? '').toString();
    final risque = rappel['risques_encourus']?.toString()
        ?? rappel['risque_produit']?.toString();
    final imageUrl = _extractFirstImageUrl(rappel);
    final cs = Theme.of(context).colorScheme;

    DateTime? parsedDate;
    bool isNew = false;
    String timeLabel = '';
    if (rappel['date_publication'] != null) {
      try {
        parsedDate = RappelService.parseDate(rappel['date_publication'].toString());
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
        curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );
    final slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
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
          child: InkWell(
            onTap: () => _openProductDetails(rappel),
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('NOUVEAU',
                                  style: TextStyle(color: cs.onPrimary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                            if (categorie.isNotEmpty)
                              Flexible(
                                child: Text(categorie,
                                  style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Titre principal
                        Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        // Marque + date
                        Row(
                          children: [
                            if (brand.isNotEmpty) ...[
                              Flexible(
                                child: Text(brand,
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (timeLabel.isNotEmpty)
                                Text('  ·  ', style: TextStyle(color: cs.outlineVariant, fontSize: 12)),
                            ],
                            if (timeLabel.isNotEmpty)
                              Text(timeLabel,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                        // Puce de risque
                        if (risque != null && risque.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                              ),
                              Flexible(
                                child: Text(risque,
                                  style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
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
                          ? _buildNetworkImageWithFallback(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (ctx) => _imagePlaceholderSquare(cs))
                          : _imagePlaceholderSquare(cs),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholderSquare(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.warning_amber_rounded, size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
      ),
    );
  }

  /// Shimmer pour la liste pendant le chargement
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
                  Container(height: 10, width: 70, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 8),
                  Container(height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 5),
                  Container(height: 14, width: 200, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 10),
                  Container(height: 10, width: 120, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(5))),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        actions: const [AppMenu()],
      ),
      body: Column(
        children: [
          // Barre de recherche unifiée
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Rechercher un produit...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadRappels();
                    },
                  ),
                FilledButton(
                  onPressed: _loadRappels,
                  child: const Text('OK'),
                ),
              ],
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (_) => _loadRappels(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 6,
                    itemBuilder: (_, __) => _buildCardShimmer(),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredRappels.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              // Compteur + tri
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_filteredRappels.length} résultats',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colorScheme.onSurfaceVariant),
                                    ),
                                    Row(children: [
                                      _buildSortChip(label: 'Récent', icon: Icons.arrow_downward, selected: _isNewestFirst, onTap: () { if (!_isNewestFirst) _toggleSortOrder(); }),
                                      const SizedBox(width: 6),
                                      _buildSortChip(label: 'Ancien', icon: Icons.arrow_upward, selected: !_isNewestFirst, onTap: () { if (_isNewestFirst) _toggleSortOrder(); }),
                                    ]),
                                  ],
                                ),
                              ),
                              // Liste style Google News
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  itemCount: _paginatedRappels.length,
                                  itemBuilder: (_, i) => _buildRappelCard(_paginatedRappels[i], i),
                                ),
                              ),
                              // Pagination
                              if (_filteredRappels.length > _pageSize)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton.outlined(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 0
                                            ? () => setState(() { _currentPage--; _staggerController.forward(from: 0); })
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text('Page ${_currentPage + 1} / ${(_filteredRappels.length / _pageSize).ceil()}',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                      IconButton.outlined(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: (_currentPage + 1) * _pageSize < _filteredRappels.length
                                            ? () => setState(() { _currentPage++; _staggerController.forward(from: 0); })
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadRappels,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualiser'),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text(
              'Impossible de charger les données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadRappels,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 48, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun rappel trouvé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'dans la catégorie "${widget.categoryTitle}"',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadRappels,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }
}
