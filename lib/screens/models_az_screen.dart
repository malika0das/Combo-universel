import 'dart:async';

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
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _filter = '';

  /// Normalising ~3,000 model names on every keystroke was the single biggest
  /// source of jank on this screen. The packed forms are computed once and
  /// reused, and typing is debounced.
  List<String>? _all;
  List<String> _packed = const [];
  List<String> _models = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _ensureIndex(List<String> all) {
    if (identical(_all, all)) return;
    _all = all;
    _packed = all
        .map((m) => SearchEngine.compact(SearchEngine.normalize(m)))
        .toList(growable: false);
    _models = all;
  }

  void _onFilterChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      final needle = SearchEngine.compact(SearchEngine.normalize(value));
      final all = _all ?? const <String>[];
      setState(() {
        _filter = value;
        if (needle.isEmpty) {
          _models = all;
        } else {
          final out = <String>[];
          for (var i = 0; i < all.length; i++) {
            if (_packed[i].contains(needle)) out.add(all[i]);
          }
          _models = out;
        }
      });
    });
  }

  /// Safe first letter — a blank or symbol-led name used to crash on `[0]`.
  static String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '#' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final SearchEngine? engine = scope.catalog.engine;
    final all = engine?.allModels ?? const <String>[];
    _ensureIndex(all);
    final models = _models;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All models'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _controller,
              onChanged: _onFilterChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter models',
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                suffixIcon: _filter.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onFilterChanged('');
                        },
                      ),
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
                    // No fixed itemExtent: rows must be free to grow with the
                    // in-app text-size slider, otherwise large text is clipped.
                    itemBuilder: (context, i) {
                      final model = models[i];
                      final showHeader =
                          i == 0 || _initial(model) != _initial(models[i - 1]);
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
                                  _initial(model),
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
