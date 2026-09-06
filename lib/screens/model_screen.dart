import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../services/search_engine.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/ui.dart';
import 'group_screen.dart';

/// Everything the catalog knows about one phone: which combo, battery, glass,
/// board and cover fit it, plus the other phones that share those parts.
class ModelScreen extends StatelessWidget {
  const ModelScreen({super.key, required this.model});

  final String model;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final engine = scope.catalog.engine;
    final scheme = Theme.of(context).colorScheme;
    final profile = engine?.profileFor(model);

    return Scaffold(
      appBar: AppBar(
        title: Text(model, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share parts sheet',
            icon: const Icon(Icons.share_outlined),
            onPressed: profile == null || profile.isEmpty
                ? null
                : () => Share.share(_sheet(profile)),
          ),
          IconButton(
            tooltip: 'Copy parts sheet',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: profile == null || profile.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                        ClipboardData(text: _sheet(profile)));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parts sheet copied')),
                      );
                    }
                  },
          ),
        ],
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: profile == null || profile.isEmpty
          ? const EmptyState(
              icon: Icons.help_outline_rounded,
              title: 'Nothing recorded yet',
              message: 'No universal parts are listed for this model.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [brandSeed, Color(0xFF3E7BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MODEL',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 9.5,
                                letterSpacing: 1.4,
                              )),
                      const SizedBox(height: 4),
                      Text(
                        profile.model,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      Gap.md,
                      Row(
                        children: [
                          _HeroStat(
                            value: '${profile.parts.length}',
                            label: profile.parts.length == 1
                                ? 'part list'
                                : 'part lists',
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            color: Colors.white24,
                          ),
                          _HeroStat(
                            value: '${profile.siblings.length}',
                            label: 'related models',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.xl,
                const SectionHeader(title: 'Parts that fit'),
                for (final part in profile.parts) ...[
                  Card(
                    child: ListTile(
                      leading: Builder(builder: (context) {
                        final tint = accentFor(part.category.icon, scheme);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(iconFor(part.category.icon),
                              size: 19, color: tint),
                        );
                      }),
                      title: Text(part.category.name),
                      subtitle: Text(
                        '${part.group.title}\n'
                        '${part.group.code} · fits ${part.group.models.length} models',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        scope.ads.maybeShowInterstitial();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => GroupScreen(
                              group: part.group, query: profile.model),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (profile.siblings.isNotEmpty) ...[
                  Gap.md,
                  SectionHeader(
                    title: 'Shares parts with',
                    subtitle: '${profile.siblings.length} models use at least '
                        'one of the same parts',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final sibling in profile.siblings.take(40))
                        ActionChip(
                          label: Text(sibling),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ModelScreen(model: sibling)),
                          ),
                        ),
                    ],
                  ),
                ],
                Gap.xl,
                const VerifyNotice(),
              ],
            ),
    );
  }

  String _sheet(ModelProfile profile) {
    final buffer = StringBuffer('Universal parts for ${profile.model}\n');
    for (final part in profile.parts) {
      buffer.writeln('\n${part.category.name}: ${part.group.title} '
          '(${part.group.code})');
      buffer.writeln('Also fits: ${part.group.models.take(12).join(', ')}'
          '${part.group.models.length > 12 ? ' …' : ''}');
    }
    buffer.write('\nvia Combo Universal app');
    return buffer.toString();
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white, height: 1.0)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
