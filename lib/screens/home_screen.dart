import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/ui.dart';
import 'category_screen.dart';
import 'compare_screen.dart';
import 'models_az_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';

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
            title: const _BrandTitle(),
            actions: [
              AnimatedBuilder(
                animation: scope.prefs,
                builder: (context, _) {
                  final count = scope.prefs.stock.length;
                  return IconButton(
                    tooltip: 'Order list',
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StockScreen()),
                    ),
                  );
                },
              ),
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
          SectionHeader(
            title: 'Recent searches',
            trailing: TextButton(
              onPressed: scope.prefs.clearRecent,
              child: const Text('Clear'),
            ),
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
          Gap.lg,
        ],
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.compare_arrows_rounded,
                label: 'Compare',
                caption: 'one part, two phones',
                tint: const Color(0xFF9B5DE5),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CompareScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.sort_by_alpha_rounded,
                label: 'A\u2013Z',
                caption: 'all models',
                tint: const Color(0xFF00A3C4),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ModelsAzScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.shopping_cart_outlined,
                label: 'Order',
                caption: 'send to supplier',
                tint: const Color(0xFF17A673),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StockScreen()),
                ),
              ),
            ),
          ],
        ),
        Gap.xl,
        SectionHeader(
          title: 'Browse by part',
          subtitle: '${scope.catalog.engine?.modelCount ?? 0} models indexed',
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: catalog.categories.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 210,
            childAspectRatio: 1.18,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, i) {
            final c = catalog.categories[i];
            return _CategoryCard(category: c);
          },
        ),
        Gap.xl,
        VerifyNotice(text: catalog.notice),
        Gap.md,
        Center(
          child: Text(
            'List v${catalog.version} · updated ${catalog.updatedAt}',
            style: theme.textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [brandSeed, Color(0xFF3E7BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.hub_rounded, size: 17, color: Colors.white),
        ),
        Gap.wSm,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Combo Universal',
                style: theme.textTheme.titleMedium?.copyWith(height: 1.05)),
            Text('Spare parts compatibility',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontSize: 9.5, letterSpacing: 0.7)),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.caption,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              Gap.sm,
              Text(label,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5)),
              const SizedBox(height: 1),
              Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Hero(
      tag: 'searchbox',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: brandSeed.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 21, color: scheme.primary),
                Gap.wMd,
                Expanded(
                  child: Text(
                    'Search a model, part or code',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.outline),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('Tap',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5)),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = accentFor(category.icon, scheme);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          AppScope.of(context).ads.maybeShowInterstitial();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category),
          ));
        },
        child: Stack(
          children: [
            // A soft tinted wash keyed to the part type, so the grid reads as
            // five distinct destinations rather than five identical boxes.
            Positioned(
              right: -26,
              top: -26,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconFor(category.icon), color: tint, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontSize: 13.5, height: 1.25),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${category.groupCount} lists · ${category.modelCount} models',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Could not load the list',
      message: 'The bundled data could not be read. Try again.',
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry'),
      ),
    );
  }
}
