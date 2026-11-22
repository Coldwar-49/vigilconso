// Feed screen for ALRT-05 - displays filtered rappels from mesAlertesProvider.
// Pass rappel.toJson() to RappelDetailsPage (still uses dynamic map access).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/providers/mes_alertes_provider.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

class MesAlertesScreen extends ConsumerWidget {
  const MesAlertesScreen({super.key});

  void _openDetails(BuildContext context, Rappel rappel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RappelDetailsPage(rappel: rappel.toJson()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 48,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun rappel pour vos abonnements',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Ajoutez des marques ou catégories depuis l'onglet Abonnements.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertesAsync = ref.watch(mesAlertesProvider);
    return alertesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5,
        itemBuilder: (_, __) => const RappelCardShimmer(),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (rappels) => rappels.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rappels.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(rappels[i].libelle),
                subtitle: Text(rappels[i].marqueProduit),
                onTap: () => _openDetails(ctx, rappels[i]),
              ),
            ),
    );
  }
}
