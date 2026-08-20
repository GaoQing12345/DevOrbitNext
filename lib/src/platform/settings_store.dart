import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrbitSettings extends ChangeNotifier {
  OrbitSettings(this._preferences, this._hotKey, this._launchAtStartup);

  final SharedPreferences _preferences;
  HotKey _hotKey;
  bool _launchAtStartup;

  HotKey get hotKey => _hotKey;
  bool get launchAtStartup => _launchAtStartup;

  static Future<OrbitSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('orbit.hotkey');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return OrbitSettings(
            preferences,
            HotKey.fromJson(decoded),
            preferences.getBool('orbit.launchAtStartup') ?? false,
          );
        }
      } on Object {
        // A malformed preference falls back to the portable default.
      }
    }
    return OrbitSettings(
      preferences,
      _defaultHotKey(),
      preferences.getBool('orbit.launchAtStartup') ?? false,
    );
  }

  Future<void> setHotKey(HotKey hotKey) async {
    _hotKey = hotKey;
    await _preferences.setString('orbit.hotkey', jsonEncode(hotKey.toJson()));
    notifyListeners();
  }

  Future<void> setLaunchAtStartup(bool enabled) async {
    _launchAtStartup = enabled;
    await _preferences.setBool('orbit.launchAtStartup', enabled);
    notifyListeners();
  }

  static HotKey _defaultHotKey() {
    return HotKey(
      identifier: 'dev-orbit-next-launcher',
      key: PhysicalKeyboardKey.space,
      modifiers: [
        defaultTargetPlatform == TargetPlatform.macOS
            ? HotKeyModifier.meta
            : HotKeyModifier.control,
        HotKeyModifier.shift,
      ],
    );
  }
}
