import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

abstract interface class DesktopHost {
  Future<void> initialize({
    required Future<void> Function() onToggleLauncher,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onHideRequested,
    required Future<void> Function() onQuitRequested,
    required VoidCallback onWindowBlur,
    required HotKey hotKey,
  });

  Future<void> showLauncher();
  Future<void> showToolWindow();
  Future<void> hide();
  Future<void> quit();
  Future<String?> updateHotKey(HotKey hotKey);
  Future<bool> setLaunchAtStartup(bool enabled);
}

class NativeDesktopHost
    with WindowListener, TrayListener
    implements DesktopHost {
  NativeDesktopHost({bool? isMacOS}) : _isMacOS = isMacOS ?? Platform.isMacOS;

  static const launcherSize = Size.square(420);
  static const toolSize = Size(1100, 760);
  static const _macWindowChannel = MethodChannel('dev_orbit/window');

  final bool _isMacOS;
  Future<void> Function()? _onToggleLauncher;
  Future<void> Function()? _onOpenSettings;
  Future<void> Function()? _onHideRequested;
  Future<void> Function()? _onQuitRequested;
  VoidCallback? _onWindowBlur;
  HotKey? _registeredHotKey;
  Rect _toolBounds = const Rect.fromLTWH(150, 120, 1100, 760);

  @override
  Future<void> initialize({
    required Future<void> Function() onToggleLauncher,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onHideRequested,
    required Future<void> Function() onQuitRequested,
    required VoidCallback onWindowBlur,
    required HotKey hotKey,
  }) async {
    _onToggleLauncher = onToggleLauncher;
    _onOpenSettings = onOpenSettings;
    _onHideRequested = onHideRequested;
    _onQuitRequested = onQuitRequested;
    _onWindowBlur = onWindowBlur;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: toolSize,
        minimumSize: Size(820, 580),
        center: true,
        title: 'Orbit Tools',
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
    );
    launchAtStartup.setup(
      appName: 'Orbit Tools',
      appPath: Platform.resolvedExecutable,
      packageName: 'com.devorbit.devOrbitNext',
    );
    await _setupTray();
    await _registerHotKey(hotKey);
    await windowManager.hide();
  }

  Future<void> _registerHotKey(HotKey hotKey) async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) => _onToggleLauncher?.call(),
    );
    _registeredHotKey = hotKey;
  }

  Future<void> _setupTray() async {
    const icon = 'assets/orbit_tray.png';
    await trayManager.setIcon(icon, isTemplate: _isMacOS);
    await trayManager.setToolTip('Orbit Tools');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'launcher', label: '打开轮盘'),
          MenuItem(key: 'settings', label: '设置'),
          MenuItem(key: 'quit', label: '退出 Orbit Tools'),
        ],
      ),
    );
  }

  @override
  Future<void> showLauncher() async {
    final currentBounds = await windowManager.getBounds();
    if (currentBounds.width >= 820 && currentBounds.height >= 580) {
      _toolBounds = currentBounds;
    }
    final cursor = await _getCursorScreenPoint();
    final displays = await screenRetriever.getAllDisplays();
    Display? target;
    for (final display in displays) {
      final position = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;
      if ((position & size).contains(cursor)) {
        target = display;
        break;
      }
    }
    final area =
        (target?.visiblePosition ?? Offset.zero) &
        (target?.visibleSize ?? target?.size ?? const Size(1440, 900));
    final x = (cursor.dx - launcherSize.width / 2)
        .clamp(area.left, area.right - launcherSize.width)
        .toDouble();
    final y = (cursor.dy - launcherSize.height / 2)
        .clamp(area.top, area.bottom - launcherSize.height)
        .toDouble();

    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.setResizable(false);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setHasShadow(false);
    await windowManager.setBounds(
      Rect.fromLTWH(x, y, launcherSize.width, launcherSize.height),
    );
    // The macOS implementation of show() activates the app asynchronously.
    // Calling focus() immediately afterwards can deactivate it again because
    // window_manager uses ignoringOtherApps: false in that method.
    await windowManager.show();
    await _activateMacWindow();
  }

  @override
  Future<void> showToolWindow() async {
    final bounds = await windowManager.getBounds();
    if (bounds.width >= 820 && bounds.height >= 580) _toolBounds = bounds;
    await windowManager.setMinimumSize(const Size(820, 580));
    await windowManager.setResizable(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setHasShadow(true);
    await windowManager.setBounds(_toolBounds);
    await windowManager.show();
    await _activateMacWindow();
  }

  Future<void> _activateMacWindow() async {
    if (_isMacOS) await _macWindowChannel.invokeMethod<void>('activate');
  }

  Future<Offset> _getCursorScreenPoint() async {
    if (!_isMacOS) return screenRetriever.getCursorScreenPoint();
    final point = await _macWindowChannel.invokeMapMethod<String, num>(
      'cursorScreenPoint',
    );
    if (point == null) return screenRetriever.getCursorScreenPoint();
    return Offset(
      (point['dx'] ?? 0).toDouble(),
      (point['dy'] ?? 0).toDouble(),
    );
  }

  @override
  Future<void> hide() async {
    final bounds = await windowManager.getBounds();
    if (bounds.width >= 820 && bounds.height >= 580) _toolBounds = bounds;
    await windowManager.hide();
  }

  @override
  Future<void> quit() async {
    await trayManager.destroy();
    if (_registeredHotKey != null) {
      await hotKeyManager.unregister(_registeredHotKey!);
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<String?> updateHotKey(HotKey hotKey) async {
    if (hotKey.modifiers?.isEmpty ?? true) {
      return '快捷键至少需要一个修饰键。';
    }
    final previous = _registeredHotKey;
    try {
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => _onToggleLauncher?.call(),
      );
      _registeredHotKey = hotKey;
      return null;
    } on Object catch (error) {
      if (previous != null) {
        try {
          await hotKeyManager.register(
            previous,
            keyDownHandler: (_) => _onToggleLauncher?.call(),
          );
          _registeredHotKey = previous;
        } on Object catch (rollbackError) {
          return '快捷键注册失败：$error；恢复旧快捷键也失败：$rollbackError';
        }
      }
      return '快捷键注册失败：$error';
    }
  }

  @override
  Future<bool> setLaunchAtStartup(bool enabled) {
    return enabled ? launchAtStartup.enable() : launchAtStartup.disable();
  }

  @override
  void onWindowClose() => _onHideRequested?.call();

  @override
  void onWindowBlur() => _onWindowBlur?.call();

  @override
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'launcher') _onToggleLauncher?.call();
    if (menuItem.key == 'settings') _onOpenSettings?.call();
    if (menuItem.key == 'quit') _onQuitRequested?.call();
  }
}
