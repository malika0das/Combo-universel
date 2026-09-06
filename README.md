# Combo Universal — Flutter Android App

Offline-first universal compatibility list (combo/display, battery, tempered glass, CC board, frame) for mobile repair technicians. Companion app for [combouniversal.com](https://combouniversal.com/) and [combosupport.in](https://combosupport.in/).

## Features
- **Smart highlight search** across every category at once, with debounce and exact-match ranking (same behaviour as the website).
- **Hybrid data**: ships with a bundled JSON catalog (works offline, instantly), silently upgrades from a remote JSON when a higher `version` is published, and caches it locally.
- Category → brand → list browsing, per-brand filter.
- Save/bookmark lists, recent searches, copy & WhatsApp share of a full list.
- Material 3 UI, dark mode, portrait-locked, no login.
- AdMob adaptive banner + throttled interstitial (1 in 6 navigations), with an in-app personalised-ads toggle.
- In-app privacy policy and disclaimer screens.

## Project layout
```
lib/
  main.dart              app bootstrap (non-blocking init)
  app_scope.dart         InheritedWidget dependency holder
  theme.dart             Material 3 theme
  models/catalog.dart    Catalog/Category/Brand/ComboGroup + search
  services/
    catalog_service.dart bundled + cached + remote catalog loading
    prefs_service.dart   recents, bookmarks, theme, ad consent (local only)
    ads_service.dart     AdMob init, banner factory, interstitial throttle
  screens/               home, category/brand, group detail, search, saved, settings, policy
  widgets/               highlight_text.dart, banner_ad_slot.dart
assets/data/catalog.json bundled seed data
store/                   Play listing, data safety, privacy policy, terms, icon source
```

## Run it
```bash
flutter pub get
flutter run
```

Point the app at your own remote catalog:
```bash
flutter run --dart-define=CATALOG_URL=https://combouniversal.com/app/catalog.json
```

## Before you publish
1. **AdMob IDs** — replace the test app ID in `android/app/src/main/AndroidManifest.xml` and the `real*` unit IDs in `lib/services/ads_service.dart`, then build with `--dart-define=USE_REAL_ADS=true`. Shipping test IDs to production, or real IDs on a dev build, both violate AdMob policy.
2. **Application ID** — currently `com.makund.combouniversal` (`android/app/build.gradle`). The existing Play listing uses `com.makund.combosupport`; use that ID instead if you are updating the same app rather than publishing a new one.
3. **Signing** — create `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
4. **Icon** — `store/icon_source.png` is a 1024px source; generate launcher densities (e.g. with `flutter_launcher_icons`) into `android/app/src/main/res/mipmap-*`.
5. **Privacy policy URL** — publish `store/PRIVACY_POLICY.md` at a public URL and enter it in Play Console.
6. **Data safety form** — copy the answers in `store/DATA_SAFETY.md`.
7. **App Links** — host `.well-known/assetlinks.json` on combouniversal.com so deep links verify (helps search discoverability).

Build the release bundle:
```bash
flutter build appbundle --release --dart-define=USE_REAL_ADS=true
```

## Publishing catalog updates without an app update
Host a JSON file with the same schema as `assets/data/catalog.json` at `CATALOG_URL`, and bump the top-level `version` integer each time you add models. Users get it on next launch or pull-to-refresh — no Play review needed.

## Policy notes baked in
- Minimal permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `AD_ID`. No location/storage/contacts, no `QUERY_ALL_PACKAGES`.
- Cleartext traffic disabled; HTTPS-only network security config.
- `targetSdk 35` (meets Play's 2025+ target API requirement).
- Interstitials never appear on app open or back press, and banners render only after load — no accidental clicks.
- Trademark disclaimer for brand names included in the listing and in-app terms.

## Tests
```bash
flutter test
```
