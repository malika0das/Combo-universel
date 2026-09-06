import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../widgets/banner_ad_slot.dart';
import 'group_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  String _query = '';
  List<SearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _query = widget.initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(_query));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () => _run(value));
  }

  void _run(String value) {
    final catalog = AppScope.of(context).catalog.catalog;
    setState(() => _hits = catalog?.search(value) ?? const []);
    if (value.trim().length >= 3 && _hits.isNotEmpty) {
      AppScope.of(context).prefs.addRecent(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = _query.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'searchbox',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery.isEmpty,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search model, e.g. Redmi 9A',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: !hasQuery
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: !hasQuery
          ? _Tips(onPick: (q) {
              _controller.text = q;
              _onChanged(q);
            })
          : _hits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 40),
                        const SizedBox(height: 12),
                        Text('No match for "${_query.trim()}"',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          'Try a shorter keyword like "9A" or "Y21".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hits.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text('${_hits.length} matching list(s)',
                          style: TextStyle(color: scheme.outline));
                    }
                    final hit = _hits[i - 1];
                    return GroupCard(
                      group: hit.group,
                      query: _query,
                      subtitle: '${hit.category.name} • ${hit.brand.name}',
                    );
                  },
                ),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips({required this.onPick});

  final ValueChanged<String> onPick;

  static const _samples = ['Redmi 9A', 'Y21', 'A10', 'Realme C11', 'Note 8'];

  @override
  Widget build(BuildContext context) {
    final recent = AppScope.of(context).prefs.recent;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          const Text('Recent', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final q in recent)
                ActionChip(label: Text(q), onPressed: () => onPick(q)),
            ],
          ),
          const SizedBox(height: 20),
        ],
        const Text('Try', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final q in _samples)
              ActionChip(label: Text(q), onPressed: () => onPick(q)),
          ],
        ),
      ],
    );
  }
}
