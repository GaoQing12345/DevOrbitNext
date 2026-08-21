import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/orbit_coordinator.dart';
import '../domain/tool_definition.dart';
import 'launcher/orbit_launcher.dart';
import 'orbit_theme.dart';
import 'settings_page.dart';
import 'tool_workspace.dart';

class OrbitApp extends StatefulWidget {
  const OrbitApp({super.key, required this.coordinator});

  final OrbitCoordinator coordinator;

  @override
  State<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends State<OrbitApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.coordinator.afterFirstFrame(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit Tools',
      debugShowCheckedModeBanner: false,
      theme: OrbitTheme.light(),
      home: AnimatedBuilder(
        animation: widget.coordinator,
        builder: (context, _) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (widget.coordinator.mode == OrbitMode.tool ||
                    widget.coordinator.mode == OrbitMode.settings) {
                  widget.coordinator.hide();
                } else {
                  widget.coordinator.hide();
                }
              },
            },
            child: Focus(
              // Let the launcher receive keyboard navigation, but do not
              // compete with native text fields when a tool is open.
              autofocus: widget.coordinator.mode == OrbitMode.launcher,
              child: Material(
                color: widget.coordinator.mode == OrbitMode.launcher
                    ? ((Platform.isWindows || Platform.isMacOS)
                          ? const Color(0xFFE9F0F1)
                          : Colors.transparent)
                    : OrbitTheme.ink,
                child: switch (widget.coordinator.mode) {
                  OrbitMode.launcher => OrbitLauncher(
                    coordinator: widget.coordinator,
                  ),
                  OrbitMode.tool => ToolWorkspace(
                    coordinator: widget.coordinator,
                  ),
                  OrbitMode.settings => SettingsPage(
                    coordinator: widget.coordinator,
                  ),
                  OrbitMode.hidden => _BootScreen(
                    coordinator: widget.coordinator,
                  ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({required this.coordinator});

  final OrbitCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final error = coordinator.startupError;
    return ColoredBox(
      color: OrbitTheme.ink,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: OrbitTheme.accent.withAlpha(22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OrbitTheme.accent.withAlpha(90)),
              ),
              child: const Icon(
                Icons.blur_circular_rounded,
                color: OrbitTheme.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              error ?? '正在启动 Orbit Tools',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: coordinator.start,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('重试'),
              ),
            ] else ...[
              const SizedBox(height: 14),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
