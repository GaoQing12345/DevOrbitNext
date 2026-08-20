import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/orbit_coordinator.dart';
import '../domain/tool_definition.dart';
import 'launcher/orbit_launcher.dart';
import 'orbit_theme.dart';
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
      theme: OrbitTheme.dark(),
      home: AnimatedBuilder(
        animation: widget.coordinator,
        builder: (context, _) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (widget.coordinator.mode == OrbitMode.tool) {
                  widget.coordinator.returnToLauncher();
                } else {
                  widget.coordinator.hide();
                }
              },
            },
            child: Focus(
              autofocus: true,
              child: Material(
                color: widget.coordinator.mode == OrbitMode.launcher
                    ? Colors.transparent
                    : OrbitTheme.ink,
                child: switch (widget.coordinator.mode) {
                  OrbitMode.launcher => OrbitLauncher(
                    coordinator: widget.coordinator,
                  ),
                  OrbitMode.tool => ToolWorkspace(
                    coordinator: widget.coordinator,
                  ),
                  OrbitMode.hidden => const SizedBox.shrink(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
