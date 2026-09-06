import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../widgets/banner_ad_slot.dart';
import 'group_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.prefs, scope.catalog]),
      builder: (context, _) {
        final catalog = scope.catalog.catalog;
        final saved = <(String, ComboGroup)>[];
        if (catalog != null) {
          for (final c in catalog.categories) {
            for (final b in c.brands) {
              for (final g in b.groups) {
                if (scope.prefs.isSaved(g.code)) {
                  saved.add(('${c.name} • ${b.name}', g));
                }
              }
            }
          }
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Saved lists')),
          bottomNavigationBar: BannerAdSlot(ads: scope.ads),
          body: saved.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Tap the bookmark icon on any list to keep it here for quick offline access.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: saved.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => GroupCard(
                    group: saved[i].$2,
                    query: '',
                    subtitle: saved[i].$1,
                  ),
                ),
        );
      },
    );
  }
}
