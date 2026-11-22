// UX-05 — Cache/live data indicator displayed on RappelListScreen.
// Takes a plain bool; isFromCacheProvider (rappel_provider.dart) feeds it.
import 'package:flutter/material.dart';

class CacheIndicator extends StatelessWidget {
  final bool fromCache;

  const CacheIndicator({super.key, required this.fromCache});

  @override
  Widget build(BuildContext context) {
    if (!fromCache) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.cached, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Données en cache — tirez pour actualiser',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
