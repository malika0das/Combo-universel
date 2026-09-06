import 'package:flutter/material.dart';

import 'services/ads_service.dart';
import 'services/catalog_service.dart';
import 'services/prefs_service.dart';

/// Tiny dependency holder so we avoid pulling in a state-management package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.catalog,
    required this.prefs,
    required this.ads,
    required super.child,
  });

  final CatalogService catalog;
  final PrefsService prefs;
  final AdsService ads;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      catalog != oldWidget.catalog ||
      prefs != oldWidget.prefs ||
      ads != oldWidget.ads;
}
