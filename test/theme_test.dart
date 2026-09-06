import 'package:combo_universal/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('theme', () {
    for (final brightness in Brightness.values) {
      test('builds for $brightness with a complete type scale', () {
        final theme = buildTheme(brightness);
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);

        final t = theme.textTheme;
        final styles = <String, TextStyle?>{
          'displayLarge': t.displayLarge,
          'headlineMedium': t.headlineMedium,
          'titleLarge': t.titleLarge,
          'titleMedium': t.titleMedium,
          'titleSmall': t.titleSmall,
          'bodyLarge': t.bodyLarge,
          'bodyMedium': t.bodyMedium,
          'bodySmall': t.bodySmall,
          'labelLarge': t.labelLarge,
          'labelSmall': t.labelSmall,
        };
        styles.forEach((name, style) {
          expect(style, isNotNull, reason: '$name missing');
          expect(style!.fontSize, isNotNull, reason: '$name has no size');
          expect(style.height, isNotNull, reason: '$name has no line height');
        });
      });

      test('type scale descends in size for $brightness', () {
        final t = buildTheme(brightness).textTheme;
        final ladder = <double>[
          t.displayLarge!.fontSize!,
          t.headlineLarge!.fontSize!,
          t.titleLarge!.fontSize!,
          t.titleMedium!.fontSize!,
          t.bodyLarge!.fontSize!,
          t.bodyMedium!.fontSize!,
          t.bodySmall!.fontSize!,
        ];
        for (var i = 1; i < ladder.length; i++) {
          expect(ladder[i], lessThan(ladder[i - 1]),
              reason: 'step $i is not smaller than the one before');
        }
      });

      test('body text meets a readable minimum size for $brightness', () {
        final t = buildTheme(brightness).textTheme;
        expect(t.bodyMedium!.fontSize, greaterThanOrEqualTo(13));
        expect(t.bodySmall!.fontSize, greaterThanOrEqualTo(12));
        expect(t.labelSmall!.fontSize, greaterThanOrEqualTo(10));
      });
    }

    test('light and dark use different backgrounds', () {
      expect(
        buildTheme(Brightness.light).scaffoldBackgroundColor,
        isNot(buildTheme(Brightness.dark).scaffoldBackgroundColor),
      );
    });

    test('component themes are configured', () {
      final theme = buildTheme(Brightness.light);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.appBarTheme.titleTextStyle, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(theme.listTileTheme.titleTextStyle, isNotNull);
    });
  });

  group('category accents', () {
    test('each part type gets a distinct accent', () {
      final scheme = buildTheme(Brightness.light).colorScheme;
      final keys = ['display', 'battery', 'glass', 'board', 'case'];
      final colors = keys.map((k) => accentFor(k, scheme)).toList();
      expect(colors.toSet().length, keys.length);
    });

    test('unknown keys fall back to the brand colour', () {
      final scheme = buildTheme(Brightness.light).colorScheme;
      expect(accentFor('something-new', scheme), scheme.primary);
    });

    test('every category icon resolves', () {
      for (final key in ['display', 'battery', 'glass', 'board', 'frame', 'case', '']) {
        expect(iconFor(key), isA<IconData>());
      }
    });
  });
}
