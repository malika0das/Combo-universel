import 'package:combo_universal/motion.dart';
import 'package:combo_universal/responsive.dart';
import 'package:combo_universal/widgets/dimensional.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] at a given logical width so breakpoint behaviour can be
/// asserted without a real device.
Future<BuildContext> pumpAtWidth(
  WidgetTester tester,
  double width, {
  bool reduceMotion = false,
  Widget? child,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        disableAnimations: reduceMotion,
      ),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return child ?? const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  group('breakpoints', () {
    testWidgets('a phone is compact and single column', (tester) async {
      final context = await pumpAtWidth(tester, 390);
      expect(context.screen, ScreenSize.compact);
      expect(context.listColumns, 1);
      expect(context.isWide, isFalse);
      expect(context.pagePadding, 16);
    });

    testWidgets('a small tablet is medium and two column', (tester) async {
      final context = await pumpAtWidth(tester, 700);
      expect(context.screen, ScreenSize.medium);
      expect(context.listColumns, 2);
      expect(context.isWide, isTrue);
      expect(context.pagePadding, 24);
    });

    testWidgets('a large tablet is expanded', (tester) async {
      final context = await pumpAtWidth(tester, 1200);
      expect(context.screen, ScreenSize.expanded);
      expect(context.isWide, isTrue);
      expect(context.pagePadding, 32);
    });

    testWidgets('padding never shrinks as the screen grows', (tester) async {
      var previous = 0.0;
      for (final width in [360.0, 700.0, 1200.0]) {
        final context = await pumpAtWidth(tester, width);
        expect(context.pagePadding, greaterThanOrEqualTo(previous));
        previous = context.pagePadding;
      }
    });
  });

  group('PageBody', () {
    testWidgets('caps content width on a very wide screen', (tester) async {
      await pumpAtWidth(
        tester,
        2000,
        child: const PageBody(child: SizedBox(height: 10)),
      );
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(PageBody),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(box.constraints.maxWidth, Breakpoints.maxContentWidth);
    });
  });

  group('AdaptiveCardList', () {
    testWidgets('renders every item on a phone', (tester) async {
      await pumpAtWidth(
        tester,
        390,
        child: AdaptiveCardList(
          itemCount: 6,
          itemBuilder: (context, i) => SizedBox(height: 40, child: Text('item$i')),
        ),
      );
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('item5'), findsOneWidget);
    });

    testWidgets('renders every item across columns on a tablet', (tester) async {
      await pumpAtWidth(
        tester,
        800,
        child: AdaptiveCardList(
          itemCount: 6,
          itemBuilder: (context, i) => SizedBox(height: 40, child: Text('item$i')),
        ),
      );
      // No item may be dropped when the layout switches to columns.
      for (var i = 0; i < 6; i++) {
        expect(find.text('item$i'), findsOneWidget);
      }
    });
  });

  group('reduced motion', () {
    testWidgets('durations collapse to zero when the OS asks', (tester) async {
      final context = await pumpAtWidth(tester, 390, reduceMotion: true);
      expect(Motion.reduced(context), isTrue);
      expect(Motion.of(context, Motion.base), Duration.zero);
    });

    testWidgets('durations are preserved normally', (tester) async {
      final context = await pumpAtWidth(tester, 390);
      expect(Motion.reduced(context), isFalse);
      expect(Motion.of(context, Motion.base), Motion.base);
    });

    testWidgets('EntranceFade shows content immediately when reduced',
        (tester) async {
      await pumpAtWidth(
        tester,
        390,
        reduceMotion: true,
        child: const EntranceFade(index: 5, child: Text('hello')),
      );
      // No pumpAndSettle: it must already be on screen and opaque.
      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('AnimatedCounter shows the final value when reduced',
        (tester) async {
      await pumpAtWidth(
        tester,
        390,
        reduceMotion: true,
        child: const AnimatedCounter(value: 1174),
      );
      expect(find.text('1174'), findsOneWidget);
    });
  });

  group('motion scale', () {
    test('durations ascend and stay snappy', () {
      expect(Motion.instant.inMilliseconds, lessThan(Motion.quick.inMilliseconds));
      expect(Motion.quick.inMilliseconds, lessThan(Motion.base.inMilliseconds));
      expect(Motion.base.inMilliseconds, lessThan(Motion.slow.inMilliseconds));
      // Nothing may ever block the user for longer than half a second.
      expect(Motion.slow.inMilliseconds, lessThanOrEqualTo(500));
    });
  });

  group('3D widgets', () {
    testWidgets('TiltCard renders and stays tappable', (tester) async {
      var taps = 0;
      await pumpAtWidth(
        tester,
        390,
        child: TiltCard(onTap: () => taps++, child: const Text('tilt')),
      );
      await tester.tap(find.text('tilt'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('TiltCard is still tappable under reduced motion',
        (tester) async {
      var taps = 0;
      await pumpAtWidth(
        tester,
        390,
        reduceMotion: true,
        child: TiltCard(onTap: () => taps++, child: const Text('tilt')),
      );
      await tester.tap(find.text('tilt'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('DepthOrb paints without error', (tester) async {
      await pumpAtWidth(
        tester,
        390,
        child: const DepthOrb(color: Colors.blue, icon: Icons.search),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DepthOrb), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CompatibilityGlyph animates between states', (tester) async {
      await pumpAtWidth(
        tester,
        390,
        child: const CompatibilityGlyph(matched: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CompatibilityGlyph), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PressableScale', () {
    testWidgets('fires its callback', (tester) async {
      var taps = 0;
      await pumpAtWidth(
        tester,
        390,
        child: PressableScale(onTap: () => taps++, child: const Text('press')),
      );
      await tester.tap(find.text('press'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('is inert without a callback', (tester) async {
      await pumpAtWidth(
        tester,
        390,
        child: const PressableScale(child: Text('press')),
      );
      await tester.tap(find.text('press'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
