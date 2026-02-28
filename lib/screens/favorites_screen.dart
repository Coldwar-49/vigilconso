import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vigiconso/services/favorites_service.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesService.getFavorites();
    if (mounted) setState(() { _favorites = favs; _isLoading = false; });
  }

  Future<void> _removeFavorite(String id) async {
    await FavoritesService.removeFavorite(id);
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retiré des favoris'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
  }

  String? _extractFirstImageUrl(dynamic imagesData) {
    if (imagesData is String && imagesData.isNotEmpty) {
      for (final part in imagesData.split(RegExp(r'[,;|\s]+'))) {
        final t = part.trim();
        if (t.startsWith('http')) return t;
      }
    } else if (imagesData is List) {
      for (final item in imagesData) {
        if (item is String && item.startsWith('http')) return item;
      }
    }
    return null;
  }

  String _proxiedUrl(String url) {
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }

  Widget _buildFavCard(Map<String, dynamic> rappel) {
    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand = rappel['marque_produit'] ?? rappel['nom_marque'] ?? '';
    final id = rappel['reference_fiche'] ?? rappel['libelle'] ?? '';
    final rawImageUrl = _extractFirstImageUrl(rappel['liens_vers_les_images']);
    final cs = Theme.of(context).colorScheme;

    String formattedDate = '';
    bool isNew = false;
    final dateStr = rappel['date_publication'] ?? '';
    if (dateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
        isNew = DateTime.now().difference(parsed).inDays <= 7;
      } catch (_) { formattedDate = dateStr; }
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RappelDetailsPage(rappel: rappel))),
        child: Column(children: [
          Stack(children: [
            AspectRatio(
              aspectRatio: 2.64,
              child: rawImageUrl != null
                  ? Image.network(
                      _proxiedUrl(rawImageUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null ? child : Container(color: cs.primaryContainer, child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
                      errorBuilder: (_, __, ___) => _imagePlaceholder(cs),
                    )
                  : _imagePlaceholder(cs),
            ),
            if (isNew)
              Positioned(top: 6, left: 6, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(6)),
                child: Text('NOUVEAU', style: TextStyle(color: cs.onPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
              )),
            Positioned(top: 4, right: 4, child: GestureDetector(
              onTap: () => _removeFavorite(id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.favorite, color: Colors.white, size: 14),
              ),
            )),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(brand, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ],
                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.calendar_today_outlined, size: 11, color: cs.primary),
                    const SizedBox(width: 3),
                    Text(formattedDate, style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme cs) => Container(
    color: cs.surfaceContainerHighest,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.image_not_supported_outlined, size: 22, color: cs.onSurfaceVariant),
      const SizedBox(height: 2),
      Text('Image indisponible', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes favoris (${_favorites.length})'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tout supprimer',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Vider les favoris'),
                    content: const Text('Supprimer tous vos favoris ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final f in List.from(_favorites)) {
                    await FavoritesService.removeFavorite(f['reference_fiche'] ?? f['libelle'] ?? '');
                  }
                  await _loadFavorites();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.favorite_border, size: 80, color: cs.surfaceContainerHighest),
                  const SizedBox(height: 16),
                  Text('Aucun favori pour le moment', style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Ajoutez des rappels depuis leur page détail.', style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                ]))
              : LayoutBuilder(builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 32 - 10) / 2;
                  final ratio = cardWidth / (cardWidth / 2.64 + 90);
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: ratio),
                    itemCount: _favorites.length,
                    itemBuilder: (_, i) => _buildFavCard(_favorites[i]),
                  );
                }),
    );
  }
}
