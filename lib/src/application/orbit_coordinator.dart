import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/tool_definition.dart';
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

  OrbitMode get mode => _mode;
  ToolId? get activeTool => _activeTool;
  int? get hoveredSlot => _hoveredSlot;

  Future<void> initialize() async {
    await host.initialize(
      onToggleLauncher: toggleLauncher,
      onHideRequested: hide,
      onQuitRequested: quit,
      onWindowBlur: () {
        if (_mode == OrbitMode.launcher) unawaited(hide());
      },
      hotKey: settings.hotKey,
    );
  }

  Future<void> afterFirstFrame() => showLauncher();

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

  Future<void> hide() async {
    if (_transitioning && _mode == OrbitMode.hidden) return;
    _mode = OrbitMode.hidden;
    _hoveredSlot = null;
    notifyListeners();
    await host.hide();
  }

  Future<void> returnToLauncher() => showLauncher();

  void setHoveredSlot(int? slot) {
    if (_hoveredSlot == slot) return;
    _hoveredSlot = slot;
    notifyListeners();
  }

  Future<void> quit() => host.quit();
}
