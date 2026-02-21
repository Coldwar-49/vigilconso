import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Retire des favoris'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
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
                    final id = f['reference_fiche'] ?? f['libelle'] ?? '';
                    await FavoritesService.removeFavorite(id);
                  }
                  await _loadFavorites();
                }
              },
            ),
        ],
      ),      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('Aucun favori pour le moment', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('Ajoutez des rappels en favoris depuis leur page detail.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final rappel = _favorites[index];
                    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
                    final brand = rappel['marque_produit'] ?? rappel['nom_marque'] ?? '';
                    final id = rappel['reference_fiche'] ?? rappel['libelle'] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RappelDetailsPage(rappel: rappel))),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.warning_amber, color: Colors.red, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (brand.isNotEmpty) Text(brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeFavorite(id),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}