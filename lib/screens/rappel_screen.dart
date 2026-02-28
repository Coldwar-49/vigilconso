import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';
import 'package:vigiconso/utils/constants.dart';
import 'package:vigiconso/widgets/app_menu.dart';

class RappelListScreen extends StatefulWidget {
  final String categoryKey;
  final String categoryTitle;

  const RappelListScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
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
    _fetchRappels();
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final jour = int.tryParse(parts[0].trim()) ?? 1;
        final mois = int.tryParse(parts[1].trim()) ?? 1;
        final annee = int.tryParse(parts[2].trim()) ?? 2000;
        if (annee >= 2000 && annee <= 2100) {
          return DateTime(annee, mois, jour);
        }
      }
    } catch (_) {}
    try {
      final match = RegExp(r'(\d{4})').firstMatch(dateStr);
      if (match != null) {
        final annee = int.parse(match.group(1)!);
        if (annee >= 2000 && annee <= 2100) {
          return DateTime(annee, 1, 1);
        }
      }
    } catch (_) {}
    for (int annee = 2020; annee <= 2030; annee++) {
      if (dateStr.contains(annee.toString())) {
        return DateTime(annee, 1, 1);
      }
    }
    return null;
  }

  void _toggleSortOrder() {
    setState(() {
      _isNewestFirst = !_isNewestFirst;
      _rappels.sort((a, b) {
        final String dateStrA = a['date_publication'] ?? '';
        final String dateStrB = b['date_publication'] ?? '';
        DateTime? dateA = _parseDate(dateStrA);
        DateTime? dateB = _parseDate(dateStrB);
        dateA ??= DateTime(1900);
        dateB ??= DateTime(1900);
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

  Future<void> _fetchRappels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Filtre date pour obtenir des données récentes.
      // L'API ignore sort ET interdit offset+limit > 10000 → on filtre par date.
      final year = DateTime.now().year - 1;
      final List<String> filters = ['date_publication >= "$year-01-01"'];

      final categoryFilter = AppConstants.getCategoryFilter(widget.categoryKey);
      if (categoryFilter.isNotEmpty) {
        filters.add('($categoryFilter)');
      }

      final apiUrl = '${AppConstants.apiBaseUrl}/records?limit=100'
          '&where=${Uri.encodeQueryComponent(filters.join(" AND "))}';

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          final List<dynamic> results = List<dynamic>.from(data['results']);

          // Tri local (API ignore sort=-date_publication)
          results.sort((a, b) {
            DateTime? dateA = _parseDate(a['date_publication'] ?? '');
            DateTime? dateB = _parseDate(b['date_publication'] ?? '');
            dateA ??= DateTime(1900);
            dateB ??= DateTime(1900);
            return _isNewestFirst
                ? dateB.compareTo(dateA)
                : dateA.compareTo(dateB);
          });

          setState(() {
            _rappels = results;
            _isLoading = false;
            _currentPage = 0;
            _applyYearFilter();
          });
          _staggerController.forward(from: 0);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Aucun résultat trouvé dans la réponse API';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erreur lors de la récupération des données: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _searchRappels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pour la recherche : on filtre sur tout le dataset sans offset
      // (la recherche textuelle est plus importante que le tri par date)
      String apiUrl = '${AppConstants.apiBaseUrl}/records?limit=100';

      final List<String> filters = [];

      final catFilter = AppConstants.getCategoryFilter(widget.categoryKey);
      if (catFilter.isNotEmpty) filters.add('($catFilter)');

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.replaceAll('"', '');
        filters.add(
          '(libelle like "%$query%" or libelle_produit like "%$query%" or '
          'nom_marque like "%$query%" or modeles_ou_references like "%$query%")',
        );
      }

      if (filters.isNotEmpty) {
        apiUrl += '&where=${Uri.encodeQueryComponent(filters.join(" AND "))}';
      }

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'] ?? [];

        results.sort((a, b) {
          final String dateStrA = a['date_publication'] ?? '';
          final String dateStrB = b['date_publication'] ?? '';
          DateTime? dateA = _parseDate(dateStrA);
          DateTime? dateB = _parseDate(dateStrB);
          dateA ??= DateTime(1900);
          dateB ??= DateTime(1900);
          return _isNewestFirst
              ? dateB.compareTo(dateA)
              : dateA.compareTo(dateB);
        });

        setState(() {
          _rappels = results;
          _isLoading = false;
          _currentPage = 0;
          _applyYearFilter();
        });
        _staggerController.forward(from: 0);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors de la recherche: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: $e';
      });
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

  /// Proxy wsrv.nl sur Web pour contourner le CORS des images
  String _proxiedUrl(String url) {
    if (!kIsWeb) return url;
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }

  /// Placeholder élégant quand aucune image n'est disponible :
  /// icône de catégorie sur fond dégradé coloré.
  Widget _categoryPlaceholder(String? categorie, ColorScheme cs) {
    final cat = (categorie ?? '').toLowerCase();
    IconData icon;
    if (cat.contains('vêtement') || cat.contains('mode') || cat.contains('habillement') || cat.contains('epi')) {
      icon = Icons.checkroom_outlined;
    } else if (cat.contains('aliment') || cat.contains('denrée') || cat.contains('boisson') || cat.contains('épicerie')) {
      icon = Icons.lunch_dining_outlined;
    } else if (cat.contains('automobile') || cat.contains('véhicule') || cat.contains('transport') || cat.contains('moto')) {
      icon = Icons.directions_car_outlined;
    } else if (cat.contains('électrique') || cat.contains('électronique') || cat.contains('appareil') || cat.contains('outil')) {
      icon = Icons.electrical_services_outlined;
    } else if (cat.contains('jouet') || cat.contains('enfant') || cat.contains('bébé') || cat.contains('puéricult')) {
      icon = Icons.toys_outlined;
    } else if (cat.contains('cosmétique') || cat.contains('hygiène') || cat.contains('beauté') || cat.contains('soin')) {
      icon = Icons.face_retouching_natural_outlined;
    } else if (cat.contains('médicament') || cat.contains('santé') || cat.contains('pharma')) {
      icon = Icons.medication_outlined;
    } else if (cat.contains('jardin') || cat.contains('bricolage')) {
      icon = Icons.handyman_outlined;
    } else if (cat.contains('animal') || cat.contains('animaux')) {
      icon = Icons.pets_outlined;
    } else if (cat.contains('alimentaire') || cat.contains('viande') || cat.contains('poisson')) {
      icon = Icons.set_meal_outlined;
    } else {
      icon = Icons.inventory_2_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 38, color: cs.primary.withOpacity(0.75)),
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
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          errorBuilder?.call(context) ??
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.image_not_supported, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
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


  /// Carte de rappel — grille 2 colonnes, image en haut, description centrée
  Widget _buildRappelCard(dynamic rappel, int index) {
    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand = rappel['marque_produit'] ?? rappel['nom_marque'] ?? '';
    final categorie = rappel['categorie_produit']?.toString();
    final imageUrl = _extractFirstImageUrl(rappel);
    final cs = Theme.of(context).colorScheme;
    bool isNew = false;
    String date = '';
    if (rappel['date_publication'] != null) {
      try {
        final parsed = _parseDate(rappel['date_publication']);
        if (parsed != null) {
          date = DateFormat('dd/MM/yyyy').format(parsed);
          isNew = DateTime.now().difference(parsed).inDays <= 7;
        }
      } catch (_) {}
    }

    final delay = (index * 0.06).clamp(0.0, 0.8);
    final slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerController, curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut)));
    final fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _staggerController, curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut)));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => _openProductDetails(rappel),
            child: Column(children: [
              // Image en haut
              Stack(children: [
                AspectRatio(
                  aspectRatio: 2.64,
                  child: imageUrl != null
                      ? _buildNetworkImageWithFallback(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (ctx) => _categoryPlaceholder(categorie, cs))
                      : _categoryPlaceholder(categorie, cs),
                ),
                if (isNew)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(6)),
                      child: Text('NOUVEAU', style: TextStyle(color: cs.onPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
              // Description centrée
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3),
                        maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(brand, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ],
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.calendar_today_outlined, size: 11, color: cs.primary),
                          const SizedBox(width: 3),
                          Text(date, style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Shimmer pour la grille pendant le chargement
  Widget _buildGridShimmer(double ratio) {
    return LayoutBuilder(builder: (context, constraints) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        margin: EdgeInsets.zero,
        child: Column(children: [
          AspectRatio(aspectRatio: 2.64, child: Container(color: cs.primaryContainer.withOpacity(0.4))),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.4), borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(height: 10, width: 80, decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.4), borderRadius: BorderRadius.circular(6))),
            ]),
          )),
        ]),
      );
    });
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
                      _fetchRappels();
                    },
                  ),
                FilledButton(
                  onPressed: _searchRappels,
                  child: const Text('OK'),
                ),
              ],
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (_) => _searchRappels(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? LayoutBuilder(builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 32 - 10) / 2;
                    final ratio = cardWidth / (cardWidth / 2.64 + 90);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: ratio),
                      itemCount: 6,
                      itemBuilder: (_, __) => _buildGridShimmer(ratio),
                    );
                  })
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
                              // Grille 2 colonnes avec stagger
                              Expanded(
                                child: LayoutBuilder(builder: (context, constraints) {
                                  final cardWidth = (constraints.maxWidth - 32 - 10) / 2;
                                  final ratio = cardWidth / (cardWidth / 2.64 + 90);
                                  return GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: ratio),
                                    itemCount: _paginatedRappels.length,
                                    itemBuilder: (_, i) => _buildRappelCard(_paginatedRappels[i], i),
                                  );
                                }),
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
        onPressed: _fetchRappels,
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
              onPressed: _fetchRappels,
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
              onPressed: _fetchRappels,
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
