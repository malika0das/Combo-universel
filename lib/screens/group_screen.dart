import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/highlight_text.dart';
import 'model_screen.dart';

/// Compact card used in brand and search lists.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.query,
    required this.subtitle,
  });

  final ComboGroup group;
  final String query;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final preview = group.models.take(4).toList();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          scope.ads.maybeShowInterstitial();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupScreen(group: group, query: query),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HighlightText(
                      text: group.title,
                      query: query,
                      maxLines: 2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: scope.prefs,
                    builder: (context, _) => IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: scope.prefs.inStockList(group.code)
                          ? 'In order list'
                          : 'Add to order list',
                      icon: Icon(
                        scope.prefs.inStockList(group.code)
                            ? Icons.shopping_cart_rounded
                            : Icons.add_shopping_cart_outlined,
                        size: 20,
                        color: scope.prefs.inStockList(group.code)
                            ? scheme.primary
                            : null,
                      ),
                      onPressed: () => scope.prefs.toggleStock(group.code),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: scope.prefs,
                    builder: (context, _) => IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Save',
                      icon: Icon(
                        scope.prefs.isSaved(group.code)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: scope.prefs.isSaved(group.code)
                            ? scheme.primary
                            : null,
                      ),
                      onPressed: () => scope.prefs.toggleSaved(group.code),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('$subtitle • ${group.quality} • ${group.models.length} models',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in preview)
                    _ModelChip(model: m, query: query),
                  if (group.models.length > preview.length)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('+${group.models.length - preview.length} more'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.model, required this.query});

  final String model;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: HighlightText(text: model, query: query, style: const TextStyle(fontSize: 12)),
    );
  }
}

Future<void> _editNote(
    BuildContext context, AppScope scope, String code, String current) async {
  final controller = TextEditingController(text: current);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Shop note'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Rs 850 • rack B2'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save')),
      ],
    ),
  );
  if (result != null) await scope.prefs.setNote(code, result);
}

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.group, this.query = ''});

  final ComboGroup group;
  final String query;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibility list'),
        actions: [
          AnimatedBuilder(
            animation: scope.prefs,
            builder: (context, _) => IconButton(
              tooltip: 'Save',
              icon: Icon(scope.prefs.isSaved(group.code)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded),
              onPressed: () => scope.prefs.toggleSaved(group.code),
            ),
          ),
          AnimatedBuilder(
            animation: scope.prefs,
            builder: (context, _) => IconButton(
              tooltip: 'Add to order list',
              icon: Icon(scope.prefs.inStockList(group.code)
                  ? Icons.shopping_cart_rounded
                  : Icons.add_shopping_cart_outlined),
              onPressed: () {
                scope.prefs.toggleStock(group.code);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(scope.prefs.inStockList(group.code)
                      ? 'Added to order list'
                      : 'Removed from order list'),
                ));
              },
            ),
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(group.shareText),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: group.shareText));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List copied')),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(group.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(group.code)),
              if (group.quality.isNotEmpty) Chip(label: Text(group.quality)),
              Chip(label: Text('${group.models.length} models')),
            ],
          ),
          if (group.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: scheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 20, color: scheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(group.note,
                          style: TextStyle(color: scheme.onTertiaryContainer)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: scope.prefs,
            builder: (context, _) {
              final note = scope.prefs.noteFor(group.code);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(note.isEmpty ? 'Add a shop note' : note),
                  subtitle: const Text('Price, shelf, supplier — stays on this device'),
                  onTap: () => _editNote(context, scope, group.code, note),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Compatible models',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < group.models.length; i++) ...[
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: scheme.surfaceContainerHighest,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                    title: HighlightText(text: group.models[i], query: query),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ModelScreen(model: group.models[i]),
                    )),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Copy model',
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: group.models[i])),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ),
                  if (i != group.models.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Always verify connector type, flex length and frame fit physically before fitting the part.',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
