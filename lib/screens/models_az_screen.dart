import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../motion.dart';
import '../responsive.dart';
import '../services/search_engine.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/ui.dart';
import 'model_screen.dart';

/// A–Z browser over every distinct phone model in the catalog, for when the
/// technician does not know the exact spelling.
class ModelsAzScreen extends StatefulWidget {
  const ModelsAzScreen({super.key});

  @override
  State<ModelsAzScreen> createState() => _ModelsAzScreenState();
}

class _ModelsAzScreenState extends State<ModelsAzScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final SearchEngine? engine = scope.catalog.engine;
    final all = engine?.allModels ?? const <String>[];
    final needle = SearchEngine.compact(SearchEngine.normalize(_filter));
    final models = needle.isEmpty
        ? all
        : all
            .where((m) => SearchEngine.compact(SearchEngine.normalize(m))
                .contains(needle))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All models'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Filter models',
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: models.isEmpty
          ? const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No model matches',
              message: 'Try fewer characters.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${models.length} models',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                ),
                Expanded(
                  child: PageBody(
                    child: ListView.builder(
                    itemCount: models.length,
                    itemExtent: 52,
                    itemBuilder: (context, i) {
                      final model = models[i];
                      final showHeader = i == 0 ||
                          model[0].toUpperCase() != models[i - 1][0].toUpperCase();
                      return ListTile(
                        dense: true,
                        leading: showHeader
                            ? Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  model[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : const SizedBox(width: 28),
                        title: Text(model),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          Haptics.tap();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ModelScreen(model: model),
                          ));
                        },
                      );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
