import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../services/search_engine.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
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
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No universal parts recorded for this model yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.model,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            )),
                        const SizedBox(height: 6),
                        Text(
                          '${profile.parts.length} universal part '
                          '${profile.parts.length == 1 ? "list" : "lists"} • '
                          '${profile.siblings.length} related models',
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Parts that fit',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final part in profile.parts) ...[
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        child: Icon(iconFor(part.category.icon),
                            size: 20, color: scheme.onSecondaryContainer),
                      ),
                      title: Text(part.category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${part.group.title}\n'
                        '${part.group.code} • fits ${part.group.models.length} models',
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
                  const SizedBox(height: 8),
                  const Text('Shares parts with',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
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
                const SizedBox(height: 20),
                Text(
                  'Always verify connector type, flex length and frame fit '
                  'physically before fitting the part.',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
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
