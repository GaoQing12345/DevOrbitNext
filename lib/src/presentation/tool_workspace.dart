import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../application/orbit_coordinator.dart';
import '../domain/tool_definition.dart';
import 'tools/diff_tool.dart';
import 'tools/json_tool.dart';
import 'tools/sql_tool.dart';
import 'tools/timestamp_tool.dart';
import 'tools/translator_tool.dart';
import 'widgets/glass_surface.dart';

class ToolWorkspace extends StatelessWidget {
  const ToolWorkspace({super.key, required this.coordinator});

  final OrbitCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final active = coordinator.activeTool ?? ToolId.json;
    final definition = definitionFor(active);
    return Scaffold(
      body: Row(
        children: [
          _WorkspaceRail(coordinator: coordinator, active: active),
          Expanded(
            child: Column(
              children: [
                _WorkspaceHeader(
                  coordinator: coordinator,
                  definition: definition,
                ),
                Expanded(child: _ToolPage(id: active)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceRail extends StatelessWidget {
  const _WorkspaceRail({required this.coordinator, required this.active});

  final OrbitCoordinator coordinator;
  final ToolId active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withAlpha(180),
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 8, 22),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF65D9C1).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF65D9C1).withAlpha(85),
                        ),
                      ),
                      child: const Icon(
                        Icons.blur_circular_rounded,
                        size: 17,
                        color: Color(0xFF65D9C1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ORBIT',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              _RailButton(
                icon: Icons.blur_circular_rounded,
                label: '启动轮盘',
                selected: false,
                onTap: coordinator.returnToLauncher,
              ),
              const SizedBox(height: 16),
              Text(
                '工具',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              for (final tool in toolDefinitions) ...[
                _RailButton(
                  icon: _iconFor(tool.id),
                  label: tool.name,
                  selected: active == tool.id,
                  color: Color(tool.accent),
                  onTap: () => coordinator.openTool(tool.id),
                ),
                const SizedBox(height: 4),
              ],
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),
              _RailButton(
                icon: Icons.keyboard_rounded,
                label: '⌘⇧Space 呼出',
                selected: false,
                onTap: () {},
              ),
              const SizedBox(height: 4),
              _RailButton(
                icon: Icons.logout_rounded,
                label: '隐藏窗口',
                selected: false,
                onTap: coordinator.hide,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? (color ?? scheme.primary)
        : scheme.onSurfaceVariant;
    return Material(
      color: selected
          ? (color ?? scheme.primary).withAlpha(26)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 11),
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? scheme.onSurface : foreground,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: foreground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 9),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.coordinator, required this.definition});

  final OrbitCoordinator coordinator;
  final ToolDefinition definition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withAlpha(220),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          AccentIcon(
            icon: _iconFor(definition.id),
            color: Color(definition.accent),
            size: 38,
          ),
          const SizedBox(width: 13),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                definition.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                definition.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const Spacer(),
          const _WindowDragHandle(),
          const SizedBox(width: 10),
          IconButton(
            tooltip: '回到轮盘',
            onPressed: coordinator.returnToLauncher,
            icon: const Icon(Icons.blur_circular_rounded),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '隐藏',
            onPressed: coordinator.hide,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }
}

class _WindowDragHandle extends StatelessWidget {
  const _WindowDragHandle();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '拖动窗口',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => windowManager.startDragging(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Icon(Icons.drag_indicator_rounded, size: 18),
        ),
      ),
    );
  }
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({required this.id});

  final ToolId id;

  @override
  Widget build(BuildContext context) => switch (id) {
    ToolId.json => const JsonTool(),
    ToolId.translator => const TranslatorTool(),
    ToolId.diff => const DiffTool(),
    ToolId.timestamp => const TimestampTool(),
    ToolId.sql => const SqlTool(),
  };
}

Future<String?> importText({List<String> extensions = const ['txt']}) async {
  final file = await openFile(
    acceptedTypeGroups: [XTypeGroup(label: 'Text', extensions: extensions)],
  );
  if (file == null) return null;
  return file.readAsString();
}

Future<bool> exportText(
  String text, {
  required String suggestedName,
  String extension = 'txt',
}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [
      XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
    ],
  );
  if (location == null) return false;
  await File(location.path).writeAsString(text);
  return true;
}

IconData _iconFor(ToolId id) => switch (id) {
  ToolId.json => Icons.data_object_rounded,
  ToolId.translator => Icons.translate_rounded,
  ToolId.diff => Icons.difference_rounded,
  ToolId.timestamp => Icons.schedule_rounded,
  ToolId.sql => Icons.storage_rounded,
};
