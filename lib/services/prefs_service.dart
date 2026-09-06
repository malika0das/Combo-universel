import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores recent searches, saved (favourite) groups and theme mode locally.
/// Nothing leaves the device - keeps the Play Data Safety form simple.
class PrefsService extends ChangeNotifier {
  static const _recentKey = 'recent_searches';
  static const _savedKey = 'saved_groups';
  static const _darkKey = 'dark_mode';
  static const _consentKey = 'ads_personalized';
  static const _listKey = 'stock_list';
  static const _notesKey = 'group_notes';
  static const _fontKey = 'font_scale';
  static const maxRecent = 12;

  SharedPreferences? _prefs;

  List<String> _recent = const [];
  List<String> _saved = const [];
  bool _dark = false;
  bool _personalizedAds = false;
  List<String> _stock = const [];
  Map<String, String> _notes = const {};
  double _fontScale = 1.0;

  List<String> get recent => _recent;
  List<String> get saved => _saved;
  bool get dark => _dark;
  bool get personalizedAds => _personalizedAds;

  /// Codes queued on the purchase / stock list.
  List<String> get stock => _stock;

  /// Free-text note the shop keeps against a part list (price, shelf, supplier).
  Map<String, String> get notes => _notes;
  double get fontScale => _fontScale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _recent = _prefs!.getStringList(_recentKey) ?? const [];
    _saved = _prefs!.getStringList(_savedKey) ?? const [];
    _dark = _prefs!.getBool(_darkKey) ?? false;
    _personalizedAds = _prefs!.getBool(_consentKey) ?? false;
    _stock = _prefs!.getStringList(_listKey) ?? const [];
    _notes = _decodeNotes(_prefs!.getStringList(_notesKey) ?? const []);
    _fontScale = _prefs!.getDouble(_fontKey) ?? 1.0;
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

  bool inStockList(String code) => _stock.contains(code);

  Future<void> toggleStock(String code) async {
    _stock = _stock.contains(code)
        ? _stock.where((e) => e != code).toList()
        : [..._stock, code];
    await _prefs?.setStringList(_listKey, _stock);
    notifyListeners();
  }

  Future<void> clearStock() async {
    _stock = const [];
    await _prefs?.setStringList(_listKey, const []);
    notifyListeners();
  }

  String noteFor(String code) => _notes[code] ?? '';

  Future<void> setNote(String code, String note) async {
    final next = Map<String, String>.from(_notes);
    if (note.trim().isEmpty) {
      next.remove(code);
    } else {
      next[code] = note.trim();
    }
    _notes = next;
    await _prefs?.setStringList(
        _notesKey, next.entries.map((e) => '${e.key}\u0000${e.value}').toList());
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.85, 1.5);
    await _prefs?.setDouble(_fontKey, _fontScale);
    notifyListeners();
  }

  static Map<String, String> _decodeNotes(List<String> raw) {
    final out = <String, String>{};
    for (final line in raw) {
      final i = line.indexOf('\u0000');
      if (i > 0) out[line.substring(0, i)] = line.substring(i + 1);
    }
    return out;
  }

  Future<void> setPersonalizedAds(bool value) async {
    _personalizedAds = value;
    await _prefs?.setBool(_consentKey, value);
    notifyListeners();
  }
}
