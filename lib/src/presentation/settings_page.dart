import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../application/orbit_coordinator.dart';
import 'orbit_theme.dart';
import 'widgets/glass_surface.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.coordinator});

  final OrbitCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = coordinator.settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withAlpha(220),
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: OrbitTheme.accent),
                  const SizedBox(width: 12),
                  Text('设置', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: '回到轮盘',
                    onPressed: coordinator.returnToLauncher,
                    icon: const Icon(Icons.blur_circular_rounded),
                  ),
                  IconButton(
                    tooltip: '隐藏窗口',
                    onPressed: coordinator.hide,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(34, 30, 34, 40),
                children: [
                  Text('启动行为', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GlassSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.power_settings_new_rounded,
                          title: '开机启动',
                          description: '登录系统后自动驻留托盘，不打开主窗口。',
                          trailing: Switch(
                            value: settings.launchAtStartup,
                            onChanged: (value) =>
                                _toggleStartup(context, value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('轮盘快捷键', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GlassSurface(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: OrbitTheme.accent.withAlpha(22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.keyboard_rounded,
                            color: OrbitTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '呼出轮盘',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              HotKeyVirtualView(hotKey: settings.hotKey),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _changeHotKey(context),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('自定义'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('关于', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GlassSurface(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.blur_circular_rounded,
                          color: OrbitTheme.accent,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Orbit Tools',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '1.0.0',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStartup(BuildContext context, bool enabled) async {
    final error = await coordinator.updateLaunchAtStartup(enabled);
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _changeHotKey(BuildContext context) async {
    final next = await showDialog<HotKey>(
      context: context,
      builder: (context) => _HotKeyDialog(current: coordinator.settings.hotKey),
    );
    if (next == null || !context.mounted) return;
    final error = await coordinator.updateHotKey(next);
    if (!context.mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 21,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 18),
        trailing,
      ],
    );
  }
}

class _HotKeyDialog extends StatefulWidget {
  const _HotKeyDialog({required this.current});

  final HotKey current;

  @override
  State<_HotKeyDialog> createState() => _HotKeyDialogState();
}

class _HotKeyDialogState extends State<_HotKeyDialog> {
  HotKey? _recorded;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('自定义轮盘快捷键'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '点击下方区域后按下新的组合键。',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: HotKeyRecorder(
                initalHotKey: widget.current,
                onHotKeyRecorded: (hotKey) {
                  _recorded = HotKey(
                    identifier: widget.current.identifier,
                    key: hotKey.key,
                    modifiers: hotKey.modifiers,
                    scope: widget.current.scope,
                  );
                  setState(() => _error = null);
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  void _save() {
    final hotKey = _recorded;
    if (hotKey == null || (hotKey.modifiers?.isEmpty ?? true)) {
      setState(() => _error = '快捷键至少需要一个修饰键，例如 Ctrl/Cmd + Shift。');
      return;
    }
    Navigator.pop(context, hotKey);
  }
}
