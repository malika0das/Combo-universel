import 'dart:convert';
import 'dart:io';

import 'package:combo_universal/models/catalog.dart';
import 'package:combo_universal/services/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests locking in behaviour that the shingle/candidate index
/// optimisation could silently break. Each of these represents a bug that was
/// found and fixed, so they must keep passing.
void main() {
  late Catalog catalog;
  late SearchEngine engine;

  setUpAll(() {
    final raw = File('assets/data/catalog.json').readAsStringSync();
    catalog = Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    engine = SearchEngine(catalog);
  });

  group('candidate index must never drop a result', () {
    test('token order does not change the result set', () {
      // The compact-shingle index alone returned zero hits for a reordered
      // query, because "9aredmi" shares no 3-gram with "redmi9a".
      final forward = engine.search('redmi 9a').hits.map((h) => h.group.code).toSet();
      final reversed = engine.search('9a redmi').hits.map((h) => h.group.code).toSet();
      expect(reversed, isNotEmpty);
      expect(reversed, equals(forward));
    });

    test('a part keyword in any position still scopes and matches', () {
      final a = engine.search('redmi 9a battery');
      final b = engine.search('battery redmi 9a');
      expect(a.scopedCategoryId, 'battery');
      expect(b.scopedCategoryId, 'battery');
      expect(a.hits.map((h) => h.group.code).toSet(),
          equals(b.hits.map((h) => h.group.code).toSet()));
    });

    test('indexed search agrees with an exhaustive scan', () {
      // Brute-force the ground truth straight from the catalog and compare.
      for (final query in ['vivo y21', 'redmi 9a', 'samsung a10', 'note 8']) {
        final needle = SearchEngine.compact(SearchEngine.normalize(query));
        final expected = <String>{};
        for (final category in catalog.categories) {
          for (final brand in category.brands) {
            for (final group in brand.groups) {
              final hit = group.models.any((m) =>
                  SearchEngine.compact(SearchEngine.normalize(m))
                      .contains(needle));
              if (hit) expected.add(group.code);
            }
          }
        }
        final actual = engine.search(query, limit: 10000)
            .hits
            .map((h) => h.group.code)
            .toSet();
        expect(actual.containsAll(expected), isTrue,
            reason: 'query "$query" dropped ${expected.difference(actual)}');
      }
    });

    test('short queries below the shingle size still work', () {
      // Under 3 characters there are no shingles, so the engine must fall back
      // to a full scan rather than returning nothing.
      expect(engine.search('a1').hits, isNotEmpty);
      expect(engine.search('9a').hits, isNotEmpty);
    });
  });

  group('result cache', () {
    test('repeated queries return identical results', () {
      final first = engine.search('vivo y21');
      final second = engine.search('vivo y21');
      expect(second.hits.length, first.hits.length);
      expect(second.hits.first.group.code, first.hits.first.group.code);
    });

    test('cache keys respect the category scope', () {
      final all = engine.search('vivo', autoScope: false);
      final scoped = engine.search('vivo', categoryId: 'battery');
      expect(scoped.hits.length, lessThan(all.hits.length));
      expect(scoped.hits.every((h) => h.category.id == 'battery'), isTrue);
    });

    test('cache keys respect the limit', () {
      expect(engine.search('vivo', limit: 5).hits.length, lessThanOrEqualTo(5));
      expect(engine.search('vivo', limit: 50).hits.length, greaterThan(5));
    });
  });

  group('autocomplete quality', () {
    test('short exact-prefix models rank ahead of longer ones', () {
      final options = engine.complete('redmi 9');
      expect(options, isNotEmpty);
      final packed = options
          .map((o) => SearchEngine.compact(SearchEngine.normalize(o)))
          .toList();
      // The shortest prefix match must be present, not lost to an early break.
      expect(packed.any((p) => p == 'redmi9'), isTrue);
    });

    test('never returns more than the requested limit', () {
      expect(engine.complete('a', limit: 4).length, lessThanOrEqualTo(4));
    });
  });

  group('robustness against odd input', () {
    test('punctuation-only and whitespace queries are safe', () {
      for (final query in ['', '   ', '!!!', '---', '  ??  ']) {
        final result = engine.search(query);
        expect(result.hits, isEmpty);
        expect(result.suggestions, isEmpty);
      }
    });

    test('a very long query does not throw', () {
      final long = 'redmi ' * 200;
      expect(() => engine.search(long), returnsNormally);
    });

    test('profileFor is safe for an unknown model', () {
      final profile = engine.profileFor('Definitely Not A Phone 9000');
      expect(profile.isEmpty, isTrue);
      expect(profile.parts, isEmpty);
      expect(profile.siblings, isEmpty);
    });

    test('suggest is bounded and never returns the impossible', () {
      final suggestions = engine.suggest('zzzzzzzzzzzzzzzzzzzz');
      expect(suggestions.length, lessThanOrEqualTo(6));
    });
  });
}
