import '../models/catalog.dart';
import 'prefs_service.dart';
import 'search_engine.dart';

/// What kind of nudge to show. Drives tone, icon and colour.
enum InsightTone { welcome, tip, streak, resume, caution }

/// A single proactive suggestion surfaced on the home screen.
class Insight {
  const Insight({
    required this.id,
    required this.tone,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionQuery,
    this.actionModel,
  });

  final String id;
  final InsightTone tone;
  final String title;
  final String message;
  final String? actionLabel;

  /// If set, tapping the action opens search with this query.
  final String? actionQuery;

  /// If set, tapping the action opens this model's profile.
  final String? actionModel;
}

/// ---------------------------------------------------------------------------
/// Proactive UX
/// ---------------------------------------------------------------------------
/// Reads local, on-device signals (time of day, recent searches, saved and
/// ordered items) and offers the *next* useful step before the user asks.
///
/// Deliberately conservative: at most one insight at a time, never nagging,
/// and every signal stays on the device.
class InsightService {
  const InsightService();

  /// Time-aware greeting. Small touch, but it makes the app feel like it is
  /// present with you rather than a static document.
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 5) return 'Working late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Working late';
  }

  /// Builds the single most relevant insight, or null when there is genuinely
  /// nothing helpful to say — silence is better than filler.
  Insight? build({
    required PrefsService prefs,
    required Catalog? catalog,
    required SearchEngine? engine,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final recent = prefs.recent;
    final stock = prefs.stock;

    // 1. Brand new user — orient them with one concrete example.
    if (recent.isEmpty && prefs.saved.isEmpty && stock.isEmpty) {
      return const Insight(
        id: 'first_run',
        tone: InsightTone.welcome,
        title: 'Start with any model',
        message:
            'Type a phone name and see every universal part that fits it. '
            'Spelling does not have to be exact.',
        actionLabel: 'Try Redmi 9A',
        actionQuery: 'Redmi 9A',
      );
    }

    // 2. An order list left sitting is the highest-value nudge — it is money.
    if (stock.length >= 3) {
      return Insight(
        id: 'order_ready',
        tone: InsightTone.streak,
        title: '${stock.length} parts on your order list',
        message: 'Send it to your supplier while you have the shop open.',
        actionLabel: 'Open order list',
      );
    }

    // 3. Repeated searching for the same phone means a real job in progress.
    final repeated = _mostRepeated(recent);
    if (repeated != null && engine != null && engine.hasModel(repeated)) {
      return Insight(
        id: 'resume_$repeated',
        tone: InsightTone.resume,
        title: 'Still working on $repeated?',
        message: 'Open its parts sheet to see every part that fits it at once.',
        actionLabel: 'Open $repeated',
        actionModel: repeated,
      );
    }

    // 4. Two recent searches and no comparison yet — teach the feature at the
    //    exact moment it becomes useful.
    if (recent.length >= 2 && engine != null) {
      final a = recent[0];
      final b = recent[1];
      if (engine.hasModel(a) && engine.hasModel(b)) {
        return Insight(
          id: 'compare_hint',
          tone: InsightTone.tip,
          title: 'Compare $a and $b',
          message: 'Check whether one part covers both before you buy stock.',
          actionLabel: 'Compare them',
        );
      }
    }

    // 5. Late-night tone shift — quieter, more human.
    if (time.hour >= 22 || time.hour < 5) {
      return const Insight(
        id: 'late',
        tone: InsightTone.caution,
        title: 'Late shift',
        message:
            'Everything here works offline, so you can keep going without a '
            'signal.',
      );
    }

    return null;
  }

  /// The query searched most often, if one clearly dominates.
  String? _mostRepeated(List<String> recent) {
    if (recent.length < 2) return null;
    final counts = <String, int>{};
    for (final q in recent) {
      final key = q.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    String? best;
    var bestCount = 1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  /// Encouraging, non-robotic wording for an empty search result. Tone matters
  /// most exactly when the app has failed the user.
  static String emptyMessage(String query, bool hasSuggestions) {
    if (hasSuggestions) {
      return 'We could not find "$query", but these look close.';
    }
    return 'No match for "$query" yet. Try a shorter keyword such as the '
        'number alone — "9A" instead of "Redmi 9A Pro Max".';
  }
}
