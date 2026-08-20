import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/orbit_coordinator.dart';
import '../../domain/tool_definition.dart';

class OrbitLauncher extends StatefulWidget {
  const OrbitLauncher({super.key, required this.coordinator});

  final OrbitCoordinator coordinator;

  @override
  State<OrbitLauncher> createState() => _OrbitLauncherState();
}

class _OrbitLauncherState extends State<OrbitLauncher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final keys = [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
          LogicalKeyboardKey.digit5,
        ];
        final index = keys.indexOf(event.logicalKey);
        if (index >= 0) {
          widget.coordinator.openTool(toolDefinitions[index].id);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedBuilder(
        animation: _entry,
        builder: (context, child) {
          final value = Curves.easeOutBack.transform(_entry.value);
          return Opacity(
            opacity: _entry.value.clamp(0, 1),
            child: Transform.scale(scale: .82 + value * .18, child: child),
          );
        },
        child: const _LauncherCanvas(),
      ),
    );
  }
}

class _LauncherCanvas extends StatelessWidget {
  const _LauncherCanvas();

  @override
  Widget build(BuildContext context) {
    final state = context
        .findAncestorWidgetOfExactType<OrbitLauncher>()!
        .coordinator;
    return Center(
      child: MouseRegion(
        onExit: (_) => state.setHoveredSlot(null),
        child: SizedBox.square(
          dimension: 390,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xD9FFFFFF),
                      border: Border.all(color: const Color(0xAAFFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33435A67),
                          blurRadius: 40,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _OrbitPainter(hoveredSlot: state.hoveredSlot),
                    ),
                  ),
                ),
              ),
              for (final tool in toolDefinitions)
                _OrbitItem(tool: tool, state: state),
              _OrbitCenter(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitItem extends StatelessWidget {
  const _OrbitItem({required this.tool, required this.state});

  final ToolDefinition tool;
  final OrbitCoordinator state;

  @override
  Widget build(BuildContext context) {
    const center = 195.0;
    const radius = 132.0;
    final angle = -math.pi / 2 + tool.slot * math.pi * 2 / 8;
    final hovered = state.hoveredSlot == tool.slot;
    final accent = Color(tool.accent);
    return Positioned(
      left: center + math.cos(angle) * radius - 36,
      top: center + math.sin(angle) * radius - 36,
      child: MouseRegion(
        onEnter: (_) => state.setHoveredSlot(tool.slot),
        onExit: (_) => state.setHoveredSlot(null),
        child: Tooltip(
          message: '${tool.name}  ${tool.slot + 1}',
          child: AnimatedScale(
            scale: hovered ? 1.12 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: InkWell(
              onTap: () => state.openTool(tool.id),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: hovered
                      ? accent.withAlpha(34)
                      : const Color(0xD9FFFFFF),
                  border: Border.all(
                    color: hovered
                        ? accent.withAlpha(210)
                        : const Color(0x8093A8B4),
                  ),
                  boxShadow: hovered
                      ? [BoxShadow(color: accent.withAlpha(45), blurRadius: 24)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(tool.id), color: accent, size: 23),
                    const SizedBox(height: 5),
                    Text(
                      tool.shortName,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitCenter extends StatelessWidget {
  const _OrbitCenter({required this.state});

  final OrbitCoordinator state;

  @override
  Widget build(BuildContext context) {
    final hovered = state.hoveredSlot == null
        ? null
        : toolDefinitions
              .where((tool) => tool.slot == state.hoveredSlot)
              .firstOrNull;
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xE6FFFFFF),
        border: Border.all(color: const Color(0xAAFFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x33435A67), blurRadius: 22)],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 130),
        child: Column(
          key: ValueKey(hovered?.id),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hovered == null
                  ? Icons.blur_circular_rounded
                  : _iconFor(hovered.id),
              color: hovered == null
                  ? const Color(0xFF65D9C1)
                  : Color(hovered.accent),
              size: 27,
            ),
            const SizedBox(height: 7),
            Text(
              hovered?.name ?? 'ORBIT',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hovered == null ? '选择工具' : '点击打开',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.hoveredSlot});

  final int? hoveredSlot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const outer = 176.0;
    const inner = 82.0;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x4A677884);
    canvas.drawCircle(center, outer, ring);
    canvas.drawCircle(center, inner, ring);
    for (var index = 0; index < 8; index++) {
      final angle = -math.pi / 2 + (index + .5) * math.pi * 2 / 8;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (inner + 9),
        center + direction * (outer - 8),
        ring,
      );
    }
    if (hoveredSlot != null) {
      final tool = toolDefinitions
          .where((tool) => tool.slot == hoveredSlot)
          .firstOrNull;
      if (tool != null) {
        final accent = Color(tool.accent);
        final angle = -math.pi / 2 + tool.slot * math.pi * 2 / 8;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outer - 2),
          angle - .28,
          .56,
          false,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.hoveredSlot != hoveredSlot;
}

IconData _iconFor(ToolId id) => switch (id) {
  ToolId.json => Icons.data_object_rounded,
  ToolId.translator => Icons.translate_rounded,
  ToolId.diff => Icons.difference_rounded,
  ToolId.timestamp => Icons.schedule_rounded,
  ToolId.sql => Icons.storage_rounded,
};
