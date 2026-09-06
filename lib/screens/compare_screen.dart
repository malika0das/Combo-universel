import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../services/search_engine.dart';
import '../theme.dart';
import '../widgets/banner_ad_slot.dart';
import 'model_screen.dart';

/// "Can I use one part for both phones?" — pick two (or more) models and see
/// which categories they share a universal part in.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key, this.initialModels = const []});

  final List<String> initialModels;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late List<String> _models = [...widget.initialModels];
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String model) {
    if (model.trim().isEmpty) return;
    if (_models.any((m) => m.toLowerCase() == model.toLowerCase())) return;
    setState(() => _models = [..._models, model]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final engine = scope.catalog.engine;
    final scheme = Theme.of(context).colorScheme;
    final profiles =
        engine == null ? <ModelProfile>[] : _models.map(engine.profileFor).toList();
    final shared = _sharedParts(profiles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare models'),
        actions: [
          if (shared.isNotEmpty)
            IconButton(
              tooltip: 'Share result',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(_summary(shared)),
            ),
          if (_models.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(() => _models = []),
            ),
        ],
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Autocomplete<String>(
            optionsBuilder: (value) {
              if (value.text.trim().length < 2) return const Iterable<String>.empty();
              return engine?.complete(value.text, limit: 8) ?? const <String>[];
            },
            onSelected: _add,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  _add(v);
                  controller.clear();
                },
                decoration: const InputDecoration(
                  hintText: 'Add a model, e.g. Redmi 9A',
                  prefixIcon: Icon(Icons.add_rounded),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in _models)
                InputChip(
                  label: Text(m),
                  onDeleted: () =>
                      setState(() => _models = _models.where((x) => x != m).toList()),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_models.length < 2)
            Card(
              color: scheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add at least two models to see which universal parts cover '
                  'both — useful before you buy stock.',
                ),
              ),
            )
          else if (shared.isEmpty)
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No shared universal part found for these models. '
                  'They need separate parts.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            )
          else ...[
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'One part covers all ${_models.length} models in '
                  '${shared.length} ${shared.length == 1 ? "category" : "categories"}.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final part in shared)
              Card(
                child: ListTile(
                  leading: Icon(iconFor(part.category.icon)),
                  title: Text(part.category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${part.group.title}\n${part.group.code}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: part.group.oneLine)),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (_models.isNotEmpty) ...[
            const Text('Per model', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final profile in profiles)
              Card(
                child: ListTile(
                  title: Text(profile.model),
                  subtitle: Text(profile.isEmpty
                      ? 'Not found in the catalog'
                      : '${profile.parts.length} part lists'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ModelScreen(model: profile.model),
                  )),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// A part is shared when the same group code appears for every model.
  List<ModelPart> _sharedParts(List<ModelProfile> profiles) {
    if (profiles.length < 2) return const [];
    if (profiles.any((p) => p.isEmpty)) return const [];
    final first = profiles.first.parts;
    return first.where((part) {
      return profiles.skip(1).every((p) =>
          p.parts.any((other) => other.group.code == part.group.code));
    }).toList();
  }

  String _summary(List<ModelPart> shared) {
    final buffer = StringBuffer('Shared universal parts\n');
    buffer.writeln('Models: ${_models.join(', ')}\n');
    for (final part in shared) {
      buffer.writeln('${part.category.name}: ${part.group.title} '
          '(${part.group.code})');
    }
    buffer.write('\nvia Combo Universal app');
    return buffer.toString();
  }
}
