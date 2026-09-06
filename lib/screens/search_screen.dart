import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../services/search_engine.dart';
import '../widgets/banner_ad_slot.dart';
import 'group_screen.dart';
import 'model_screen.dart';

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
  String? _categoryId;
  SearchResult _result = const SearchResult(
      hits: [], suggestions: [], scopedCategoryId: null, fuzzy: false);
  List<String> _completions = const [];

  List<SearchHit> get _hits => _result.hits;

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
    final engine = AppScope.of(context).catalog.engine;
    setState(() {
      _query = value;
      _completions = engine?.complete(value, limit: 6) ?? const [];
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () => _run(value));
  }

  void _run(String value) {
    final scope = AppScope.of(context);
    final engine = scope.catalog.engine;
    final result = engine?.search(value, categoryId: _categoryId) ??
        const SearchResult(
            hits: [], suggestions: [], scopedCategoryId: null, fuzzy: false);
    setState(() => _result = result);
    if (value.trim().length >= 3 && result.hits.isNotEmpty) {
      scope.prefs.addRecent(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = _query.trim().isNotEmpty;
    final categories = scope.catalog.catalog?.categories ?? const <Category>[];
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
      body: Column(
        children: [
          if (hasQuery && categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _categoryId == null,
                      onSelected: (_) {
                        setState(() => _categoryId = null);
                        _run(_query);
                      },
                    ),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) {
                          setState(() => _categoryId = c.id);
                          _run(_query);
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _buildResults(context, hasQuery, scheme, categories)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool hasQuery, ColorScheme scheme,
      List<Category> categories) {
    return !hasQuery
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
                        if (_result.suggestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Did you mean',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final s in _result.suggestions)
                                ActionChip(
                                  label: Text(s),
                                  onPressed: () {
                                    _controller.text = s;
                                    _onChanged(s);
                                  },
                                ),
                            ],
                          ),
                        ],
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
                      String? scopedName;
                      final scopedId = _result.scopedCategoryId;
                      if (scopedId != null) {
                        for (final c in categories) {
                          if (c.id == scopedId) scopedName = c.name;
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_completions.isNotEmpty)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final c in _completions)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        avatar: const Icon(
                                            Icons.phone_iphone_rounded, size: 16),
                                        label: Text(c),
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => ModelScreen(model: c)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            '${_hits.length} matching list(s)'
                            '${scopedName == null ? '' : ' in $scopedName'}'
                            '${_result.fuzzy ? ' • showing close matches' : ''}',
                            style: TextStyle(color: scheme.outline),
                          ),
                        ],
                      );
                    }
                    final hit = _hits[i - 1];
                    return GroupCard(
                      group: hit.group,
                      query: _query,
                      subtitle: '${hit.category.name} • ${hit.brand.name}',
                    );
                  },
                );
  }
}

class _Tips extends StatelessWidget {
  const _Tips({required this.onPick});

  final ValueChanged<String> onPick;

  static const _samples = [
    'Redmi 9A',
    'Y21',
    'A10',
    'Realme C11',
    'rn9pro',
    'Redmi 9A battery',
    'Vivo Y17 glass',
  ];

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
