import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vigiconso/providers/favorites_provider.dart';
import 'package:vigiconso/services/favorites_service.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';
import 'package:vigiconso/utils/image_utils.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {

  Future<void> _removeFavorite(String id) async {
    await FavoritesService.removeFavorite(id);
    ref.invalidate(favoritesProvider); // trigger provider rebuild
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
                      ImageUtils.proxiedUrl(rawImageUrl),
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
            child: ClipRect(
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
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

  Widget _buildEmptyState(ColorScheme cs) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.favorite_border, size: 80, color: cs.surfaceContainerHighest),
    const SizedBox(height: 16),
    Text('Aucun favori pour le moment', style: TextStyle(fontSize: 18, color: cs.onSurfaceVariant)),
    const SizedBox(height: 8),
    Text('Ajoutez des rappels depuis leur page détail.', style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
  ]));

  Widget _buildGrid(List<Map<String, dynamic>> favorites) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 32 - 10) / 2;
      final ratio = cardWidth / (cardWidth / 2.64 + 90);
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: ratio),
        itemCount: favorites.length,
        itemBuilder: (_, i) => _buildFavCard(favorites[i]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: favoritesAsync.when(
          data: (favs) => Text('Mes favoris (${favs.length})'),
          loading: () => const Text('Mes favoris'),
          error: (_, __) => const Text('Mes favoris'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          favoritesAsync.when(
            data: (favs) => favs.isNotEmpty
                ? IconButton(
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
                        final maps = await FavoritesService.getFavorites();
                        for (final f in maps) {
                          await FavoritesService.removeFavorite(f['reference_fiche'] ?? f['libelle'] ?? '');
                        }
                        ref.invalidate(favoritesProvider);
                      }
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: favoritesAsync.when(
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const RappelCardShimmer(),
        ),
        error: (e, _) => _buildEmptyState(cs),
        data: (favorites) {
          final maps = favorites.map((r) => r.toJson()).toList();
          return maps.isEmpty
              ? _buildEmptyState(cs)
              : _buildGrid(maps);
        },
      ),
    );
  }
}
