// ALRT-04 CRUD management screen + ALRT-05 feed via inner DefaultTabController.
// Sub-tabs: "Fil" (MesAlertesScreen) + "Abonnements" (brands + categories).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/providers/subscription_provider.dart';
import 'package:vigiconso/screens/mes_alertes_screen.dart';
import 'package:vigiconso/utils/constants.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

class AlertesScreen extends ConsumerStatefulWidget {
  const AlertesScreen({super.key});

  @override
  ConsumerState<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends ConsumerState<AlertesScreen> {
  final _addBrandController = TextEditingController();

  @override
  void dispose() {
    _addBrandController.dispose();
    super.dispose();
  }

  void _showAddBrandDialog() {
    _addBrandController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suivre une marque'),
        content: TextField(
          controller: _addBrandController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Nestlé, Samsung...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final brand = _addBrandController.text.trim();
              if (brand.isNotEmpty) {
                ref.read(subscriptionProvider.notifier).addBrand(brand);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Suivre'),
          ),
        ],
      ),
    );
  }

  Widget _buildAbonnementsTab(BuildContext context) {
    final subsAsync = ref.watch(subscriptionProvider);
    return subsAsync.when(
      loading: () => ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => const RappelCardShimmer(),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (subs) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marques suivies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Ajouter une marque',
                onPressed: _showAddBrandDialog,
              ),
            ],
          ),
          if (subs.brands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune marque suivie.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...subs.brands.map(
              (brand) => ListTile(
                title: Text(brand),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Ne plus suivre',
                  onPressed: () {
                    ref.read(subscriptionProvider.notifier).removeBrand(brand);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marque "$brand" retirée'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
          const Divider(height: 32),
          Text(
            'Catégories suivies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.categories.entries
                .where((e) => e.key != 'all')
                .map(
                  (e) => FilterChip(
                    label: Text(e.value),
                    selected: subs.categories.contains(e.key),
                    onSelected: (selected) {
                      final notifier = ref.read(subscriptionProvider.notifier);
                      if (selected) {
                        notifier.addCategory(e.key);
                      } else {
                        notifier.removeCategory(e.key);
                      }
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alertes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fil'),
              Tab(text: 'Abonnements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const MesAlertesScreen(),
            _buildAbonnementsTab(context),
          ],
        ),
      ),
    );
  }
}
