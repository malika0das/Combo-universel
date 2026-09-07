import 'dart:convert';
import 'dart:io';

import 'package:combo_universal/models/catalog.dart';
import 'package:combo_universal/services/insight_service.dart';
import 'package:combo_universal/services/prefs_service.dart';
import 'package:combo_universal/services/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives PrefsService through its real API against an in-memory backing store.
Future<PrefsService> makePrefs({
  List<String> recent = const [],
  List<String> saved = const [],
  List<String> stock = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'recent_searches': recent,
    'saved_groups': saved,
    'stock_list': stock,
  });
  final prefs = PrefsService();
  await prefs.init();
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Catalog catalog;
  late SearchEngine engine;
  const service = InsightService();

  setUpAll(() {
    final raw = File('assets/data/catalog.json').readAsStringSync();
    catalog = Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    engine = SearchEngine(catalog);
  });

  group('greeting', () {
    test('shifts with the clock', () {
      expect(InsightService.greeting(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(InsightService.greeting(DateTime(2026, 1, 1, 14)), 'Good afternoon');
      expect(InsightService.greeting(DateTime(2026, 1, 1, 19)), 'Good evening');
      expect(InsightService.greeting(DateTime(2026, 1, 1, 23)), 'Working late');
      expect(InsightService.greeting(DateTime(2026, 1, 1, 3)), 'Working late');
    });
  });

  group('proactive insights', () {
    test('a brand new user is oriented with a concrete example', () async {
      final prefs = await makePrefs();
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(insight, isNotNull);
      expect(insight!.tone, InsightTone.welcome);
      expect(insight.actionQuery, isNotNull);
    });

    test('a waiting order list outranks other nudges', () async {
      final prefs = await makePrefs(
        recent: ['Redmi 9A', 'Redmi 9A'],
        stock: ['A', 'B', 'C'],
      );
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(insight!.tone, InsightTone.streak);
      expect(insight.title, contains('3'));
    });

    test('a repeatedly searched model offers to resume', () async {
      final prefs = await makePrefs(recent: ['Redmi 9A', 'Redmi 9A', 'Vivo Y21']);
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(insight!.tone, InsightTone.resume);
      expect(insight.actionModel, 'Redmi 9A');
    });

    test('two distinct recents teach compare at the useful moment', () async {
      final prefs = await makePrefs(recent: ['Redmi 9A', 'Vivo Y21']);
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(insight!.tone, InsightTone.tip);
      expect(insight.id, 'compare_hint');
    });

    test('late at night the tone softens', () async {
      final prefs = await makePrefs(recent: ['zzz nonexistent query']);
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 23),
      );
      expect(insight!.tone, InsightTone.caution);
    });

    test('says nothing when there is nothing useful to say', () async {
      final prefs = await makePrefs(recent: ['zzz nonexistent query']);
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      );
      expect(insight, isNull);
    });

    test('every insight has a non-empty id, title and message', () async {
      final prefs = await makePrefs();
      final insight = service.build(
        prefs: prefs,
        catalog: catalog,
        engine: engine,
        now: DateTime(2026, 1, 1, 10),
      )!;
      expect(insight.id, isNotEmpty);
      expect(insight.title, isNotEmpty);
      expect(insight.message, isNotEmpty);
    });
  });

  group('emotional tone of failure states', () {
    test('names the query so the user knows we heard them', () {
      final message = InsightService.emptyMessage('Redmi 99Z', false);
      expect(message, contains('Redmi 99Z'));
      // Offers a way forward rather than a dead end.
      expect(message.toLowerCase(), contains('try'));
    });

    test('softens the failure when suggestions exist', () {
      final message = InsightService.emptyMessage('Redmi 9AA', true);
      expect(message.toLowerCase(), contains('close'));
    });
  });

  group('dismissal is remembered', () {
    test('a dismissed insight stays dismissed', () async {
      final prefs = await makePrefs();
      expect(prefs.isInsightDismissed('first_run'), isFalse);
      await prefs.dismissInsight('first_run');
      expect(prefs.isInsightDismissed('first_run'), isTrue);
    });

    test('dismissing twice does not duplicate', () async {
      final prefs = await makePrefs();
      await prefs.dismissInsight('x');
      await prefs.dismissInsight('x');
      expect(prefs.dismissedInsights.where((e) => e == 'x').length, 1);
    });
  });
}
