import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../domain/tool_definition.dart';
import '../platform/clipboard_bridge.dart';
import '../platform/desktop_host.dart';
import '../platform/settings_store.dart';

class OrbitCoordinator extends ChangeNotifier {
  OrbitCoordinator({required this.host, required this.settings});

  final DesktopHost host;
  final OrbitSettings settings;

  OrbitMode _mode = OrbitMode.hidden;
  ToolId? _activeTool;
  int? _hoveredSlot;
  bool _transitioning = false;
  bool _initializing = false;
  bool _initialized = false;
  String? _startupError;

  OrbitMode get mode => _mode;
  ToolId? get activeTool => _activeTool;
  int? get hoveredSlot => _hoveredSlot;
  bool get initializing => _initializing;
  String? get startupError => _startupError;

  Future<void> initialize() async {
    await host.initialize(
      onToggleLauncher: toggleLauncher,
      onOpenSettings: showSettings,
      onHideRequested: hide,
      onQuitRequested: quit,
      onWindowBlur: () {
        OrbitClipboardBridge.instance.onWindowBlur();
        if (_mode == OrbitMode.launcher) unawaited(hide());
      },
      hotKey: settings.hotKey,
    );
    _initialized = true;
  }

  Future<void> start() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _startupError = null;
    notifyListeners();
    try {
      await initialize();
      await host.hide();
    } on Object catch (error) {
      _initialized = false;
      _startupError = '桌面启动失败：$error';
      _mode = OrbitMode.hidden;
      notifyListeners();
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> afterFirstFrame() => start();

  Future<void> toggleLauncher() async {
    if (_mode == OrbitMode.launcher) {
      await hide();
    } else {
      await showLauncher();
    }
  }

  Future<void> showLauncher() async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      _mode = OrbitMode.launcher;
      _activeTool = null;
      notifyListeners();
      await host.showLauncher();
    } finally {
      _transitioning = false;
    }
  }

  Future<void> openTool(ToolId id) async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      _activeTool = id;
      _mode = OrbitMode.tool;
      _hoveredSlot = null;
      notifyListeners();
      await host.showToolWindow();
    } finally {
      _transitioning = false;
    }
  }

  Future<void> showSettings() async {
    if (_transitioning) return;
    _transitioning = true;
    try {
      _activeTool = null;
      _mode = OrbitMode.settings;
      _hoveredSlot = null;
      notifyListeners();
      await host.showToolWindow();
    } finally {
      _transitioning = false;
    }
  }

  Future<void> hide() async {
    if (_transitioning && _mode == OrbitMode.hidden) return;
    _mode = OrbitMode.hidden;
    _hoveredSlot = null;
    notifyListeners();
    await host.hide();
  }

  Future<void> returnToLauncher() => showLauncher();

  Future<String?> updateHotKey(HotKey hotKey) async {
    final error = await host.updateHotKey(hotKey);
    if (error == null) await settings.setHotKey(hotKey);
    notifyListeners();
    return error;
  }

  Future<String?> updateLaunchAtStartup(bool enabled) async {
    try {
      final success = await host.setLaunchAtStartup(enabled);
      if (!success) return '系统拒绝了开机启动设置。';
      await settings.setLaunchAtStartup(enabled);
      notifyListeners();
      return null;
    } on Object catch (error) {
      return '更新开机启动失败：$error';
    }
  }

  void setHoveredSlot(int? slot) {
    if (_hoveredSlot == slot) return;
    _hoveredSlot = slot;
    notifyListeners();
  }

  Future<void> quit() => host.quit();
}
