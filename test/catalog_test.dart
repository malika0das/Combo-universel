import 'dart:convert';
import 'dart:io';

import 'package:combo_universal/models/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Catalog catalog;

  setUpAll(() {
    final raw = File('assets/data/catalog.json').readAsStringSync();
    catalog = Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('bundled catalog parses with categories and models', () {
    expect(catalog.categories, isNotEmpty);
    expect(catalog.categories.first.modelCount, greaterThan(0));
  });

  test('group codes are unique (saved-list keys depend on this)', () {
    final codes = <String>[];
    for (final c in catalog.categories) {
      for (final b in c.brands) {
        for (final g in b.groups) {
          codes.add(g.code);
        }
      }
    }
    expect(codes.toSet().length, codes.length);
  });

  test('search is case insensitive and partial', () {
    expect(catalog.search('redmi 9a'), isNotEmpty);
    expect(catalog.search('9A'), isNotEmpty);
    expect(catalog.search(''), isEmpty);
    expect(catalog.search('nonexistent model xyz'), isEmpty);
  });

  test('exact model matches rank first', () {
    final hits = catalog.search('Redmi 9A');
    expect(hits.first.exact, isTrue);
  });

  test('share text includes every model', () {
    final group = catalog.categories.first.brands.first.groups.first;
    for (final m in group.models) {
      expect(group.shareText, contains(m));
    }
  });
}
