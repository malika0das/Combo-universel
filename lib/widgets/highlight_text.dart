import 'package:flutter/material.dart';

/// Renders [text] with every occurrence of [query] highlighted - the same
/// "smart highlight search" behaviour as the website.
class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final scheme = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    var start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: TextStyle(
          backgroundColor: scheme.tertiaryContainer,
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w700,
          // A hair of tracking stops the highlighted run from looking cramped
          // against its background.
          letterSpacing: 0.15,
        ),
      ));
      start = idx + q.length;
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
