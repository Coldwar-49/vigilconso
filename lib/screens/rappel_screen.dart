import 'dart:convert';
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

class _RappelListScreenState extends State<RappelListScreen> {
  bool _isNewestFirst = true;
  List<dynamic> _rappels = [];
  List<dynamic> _filteredRappels = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = AppConstants.pageSize;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
      final int currentYear = DateTime.now().year;
      _filteredRappels = _rappels.where((rappel) {
        final String dateStr = rappel['date_publication'] ?? '';
        final DateTime? date = _parseDate(dateStr);
        return date != null && date.year == currentYear;
      }).toList();
      _currentPage = 0;
    });
  }

  Future<void> _fetchRappels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String apiUrl = '${AppConstants.apiBaseUrl}/records?limit=100';
      apiUrl += '&sort=-date_publication';

      final categoryFilter = AppConstants.getCategoryFilter(widget.categoryKey);
      if (categoryFilter.isNotEmpty) {
        final encodedFilter = Uri.encodeComponent(categoryFilter);
        apiUrl += '&where=$encodedFilter';
      }

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          List<dynamic> results = data['results'];

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
      String apiUrl = '${AppConstants.apiBaseUrl}/records?limit=100';
      apiUrl += '&sort=-date_publication';

      List<String> filters = [];

      final categoryFilter = AppConstants.getCategoryFilter(widget.categoryKey);
      if (categoryFilter.isNotEmpty) {
        filters.add('($categoryFilter)');
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.replaceAll('"', '');
        final searchFilter =
            '(libelle like "%$query%" or libelle_produit like "%$query%" or '
            'nom_marque like "%$query%" or modeles_ou_references like "%$query%")';
        filters.add(searchFilter);
      }

      if (filters.isNotEmpty) {
        final combinedFilter = filters.join(" AND ");
        apiUrl += '&where=${Uri.encodeQueryComponent(combinedFilter)}';
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

  String? _extractFirstImageUrl(dynamic rappel) {
    final imagesText = rappel['liens_vers_les_images'] ?? '';
    if (imagesText.isEmpty) return null;

    final rawUrls = imagesText.split(RegExp(r'[,;\s]+'));
    for (var url in rawUrls) {
      final trimmedUrl = url.trim();
      if (trimmedUrl.startsWith('http')) {
        return trimmedUrl.replaceAll('"', '').replaceAll("'", "");
      }
    }
    return null;
  }

  Widget _buildNetworkImageWithFallback(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext)? errorBuilder,
  }) {
    try {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/images/placeholder.png',
        image: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        imageErrorBuilder: (context, error, stackTrace) {
          return errorBuilder?.call(context) ??
              Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported,
                    size: 40, color: Colors.grey),
              );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 40, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'Image non disponible',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        elevation: 2,
        actions: const [AppMenu()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (_) => _searchRappels(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchRappels,
                  child: const Text('Rechercher'),
                ),
              ],
            ),
          ),
          // Plus de bouton ou switch de filtre d'année ici
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(_errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchRappels,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredRappels.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blue, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun rappel trouvé pour l\'année $currentYear dans la catégorie "${widget.categoryTitle}"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchRappels,
                                  child: const Text('Rafraîchir'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_filteredRappels.length} résultats trouvés',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _toggleSortOrder,
                                      icon: Icon(_isNewestFirst
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward),
                                      label: Text(_isNewestFirst
                                          ? 'Plus récent'
                                          : 'Plus ancien'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _paginatedRappels.length,
                                  itemBuilder: (context, index) {
                                    final rappel = _paginatedRappels[index];
                                    final title = rappel['libelle'] ??
                                        rappel['libelle_produit'] ??
                                        'Produit sans nom';
                                    final brand = rappel['marque_produit'] ??
                                        rappel['nom_marque'] ??
                                        'Marque inconnue';

                                    String date = 'Date inconnue';
                                    if (rappel['date_publication'] != null) {
                                      try {
                                        final parsedDate = _parseDate(
                                            rappel['date_publication']);
                                        if (parsedDate != null) {
                                          date = DateFormat('dd/MM/yyyy')
                                              .format(parsedDate);
                                        } else if (rappel['date_publication']
                                            .toString()
                                            .contains('/')) {
                                          date = rappel['date_publication'];
                                        }
                                      } catch (e) {
                                        date = rappel['date_publication'] ??
                                            'Date inconnue';
                                      }
                                    }

                                    final imageUrl =
                                        _extractFirstImageUrl(rappel);

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: InkWell(
                                        onTap: () =>
                                            _openProductDetails(rappel),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: imageUrl != null
                                                    ? _buildNetworkImageWithFallback(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (context) =>
                                                                Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 40,
                                                            color: Colors.grey),
                                                      ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(title,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16)),
                                                    const SizedBox(height: 8),
                                                    Text('Marque: $brand'),
                                                    const SizedBox(height: 4),
                                                    Text('Publié le: $date'),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (_filteredRappels.length > _pageSize)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 0
                                            ? () =>
                                                setState(() => _currentPage--)
                                            : null,
                                      ),
                                      Text(
                                        'Page ${_currentPage + 1} / ${(_filteredRappels.length / _pageSize).ceil()}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: (_currentPage + 1) *
                                                    _pageSize <
                                                _filteredRappels.length
                                            ? () =>
                                                setState(() => _currentPage++)
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
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRappels,
        tooltip: 'Rafraîchir',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
