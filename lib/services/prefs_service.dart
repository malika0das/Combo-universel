import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores recent searches, saved (favourite) groups and theme mode locally.
/// Nothing leaves the device - keeps the Play Data Safety form simple.
class PrefsService extends ChangeNotifier {
  static const _recentKey = 'recent_searches';
  static const _savedKey = 'saved_groups';
  static const _darkKey = 'dark_mode';
  static const _consentKey = 'ads_personalized';
  static const maxRecent = 12;

  SharedPreferences? _prefs;

  List<String> _recent = const [];
  List<String> _saved = const [];
  bool _dark = false;
  bool _personalizedAds = false;

  List<String> get recent => _recent;
  List<String> get saved => _saved;
  bool get dark => _dark;
  bool get personalizedAds => _personalizedAds;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _recent = _prefs!.getStringList(_recentKey) ?? const [];
    _saved = _prefs!.getStringList(_savedKey) ?? const [];
    _dark = _prefs!.getBool(_darkKey) ?? false;
    _personalizedAds = _prefs!.getBool(_consentKey) ?? false;
    notifyListeners();
  }

  Future<void> addRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ..._recent.where((e) => e.toLowerCase() != q.toLowerCase())];
    _recent = next.take(maxRecent).toList();
    await _prefs?.setStringList(_recentKey, _recent);
    notifyListeners();
  }

  Future<void> clearRecent() async {
    _recent = const [];
    await _prefs?.setStringList(_recentKey, const []);
    notifyListeners();
  }

  bool isSaved(String code) => _saved.contains(code);

  Future<void> toggleSaved(String code) async {
    _saved = _saved.contains(code)
        ? (_saved.where((e) => e != code).toList())
        : [..._saved, code];
    await _prefs?.setStringList(_savedKey, _saved);
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _dark = value;
    await _prefs?.setBool(_darkKey, value);
    notifyListeners();
  }

  Future<void> setPersonalizedAds(bool value) async {
    _personalizedAds = value;
    await _prefs?.setBool(_consentKey, value);
    notifyListeners();
  }
}
