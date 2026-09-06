import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import 'category_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.catalog, scope.prefs]),
      builder: (context, _) {
        final catalog = scope.catalog.catalog;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Combo Universal'),
            actions: [
              IconButton(
                tooltip: 'Saved lists',
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BannerAdSlot(ads: scope.ads),
          body: scope.catalog.loading
              ? const Center(child: CircularProgressIndicator())
              : catalog == null
                  ? _ErrorState(onRetry: () => scope.catalog.init())
                  : RefreshIndicator(
                      onRefresh: () async {
                        final updated = await scope.catalog
                            .refreshFromRemote(userInitiated: true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(updated
                                ? 'List updated to the latest version.'
                                : 'You already have the latest list.'),
                          ));
                        }
                      },
                      child: _Body(catalog: catalog),
                    ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final recent = scope.prefs.recent;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SearchBox(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        const SizedBox(height: 16),
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text('Recent searches', style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: scope.prefs.clearRecent,
                child: const Text('Clear'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final q in recent)
                ActionChip(
                  label: Text(q),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => SearchScreen(initialQuery: q)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text('Categories', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: catalog.categories.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, i) {
            final c = catalog.categories[i];
            return _CategoryCard(category: c);
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    catalog.notice,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'List version ${catalog.version} • updated ${catalog.updatedAt}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Hero(
      tag: 'searchbox',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search model e.g. Redmi 9A, Y21, A10',
                    style: TextStyle(color: scheme.outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppScope.of(context).ads.maybeShowInterstitial();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Icon(iconFor(category.icon),
                    color: scheme.onPrimaryContainer, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('${category.groupCount} lists • ${category.modelCount} models',
                      style: TextStyle(fontSize: 12, color: scheme.outline)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40),
          const SizedBox(height: 12),
          const Text('Could not load the list.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
