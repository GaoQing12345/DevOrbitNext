import 'package:flutter/material.dart';

import '../../domain/text_compare_engine.dart';
import '../../domain/text_compare_models.dart';
import '../tool_workspace.dart';
import 'tool_primitives.dart';

class DiffTool extends StatefulWidget {
  const DiffTool({super.key});

  @override
  State<DiffTool> createState() => _DiffToolState();
}

class _DiffToolState extends State<DiffTool> {
  final _left = TextEditingController(
    text: 'const orbit = true;\nconst tools = 5;',
  );
  final _right = TextEditingController(
    text: 'const orbit = true;\nconst tools = 6;\nconst glass = true;',
  );
  TextDiffResult? _result;
  TextCompareOptions _options = const TextCompareOptions();

  @override
  void initState() {
    super.initState();
    _compare();
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  void _compare() => setState(
    () => _result = const TextCompareEngine().compare(
      left: _left.text,
      right: _right.text,
      options: _options,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolCanvas(
      header: Row(
        children: [
          FilterChip(
            label: const Text('忽略大小写'),
            selected: _options.ignoreCase,
            onSelected: (value) {
              setState(() => _options = _options.copyWith(ignoreCase: value));
              _compare();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('忽略行尾空格'),
            selected: _options.ignoreTrailingWhitespace,
            onSelected: (value) {
              setState(
                () => _options = _options.copyWith(
                  ignoreTrailingWhitespace: value,
                ),
              );
              _compare();
            },
          ),
          const Spacer(),
          if (result != null) ...[
            CountBadge(
              label: '新增',
              value: result.addedCount,
              color: const Color(0xFF65D9C1),
            ),
            const SizedBox(width: 6),
            CountBadge(
              label: '删除',
              value: result.removedCount,
              color: const Color(0xFFFF8F92),
            ),
            const SizedBox(width: 6),
            CountBadge(
              label: '修改',
              value: result.modifiedCount,
              color: const Color(0xFFFFB86B),
            ),
          ],
          const SizedBox(width: 10),
          IconButton(
            tooltip: '导入左侧文件',
            onPressed: () async {
              final text = await importText();
              if (text != null) setState(() => _left.text = text);
              _compare();
            },
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: '导入右侧文件',
            onPressed: () async {
              final text = await importText();
              if (text != null) setState(() => _right.text = text);
              _compare();
            },
            icon: const Icon(Icons.file_open_rounded),
          ),
        ],
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final vertical = constraints.maxWidth < 900;
            final left = _DiffEditor(
              label: 'A / 原文',
              controller: _left,
              color: const Color(0xFFFF8F92),
              onChanged: (_) => _compare(),
            );
            final right = _DiffEditor(
              label: 'B / 新文',
              controller: _right,
              color: const Color(0xFF65D9C1),
              onChanged: (_) => _compare(),
            );
            return vertical
                ? Column(children: [left, const SizedBox(height: 14), right])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 14),
                      Expanded(child: right),
                    ],
                  );
          },
        ),
        if (result != null) ...[
          const SizedBox(height: 14),
          ToolPanel(
            title: '变化概览',
            child: _DiffSummary(result: result),
          ),
        ],
      ],
    );
  }
}

class _DiffEditor extends StatelessWidget {
  const _DiffEditor({
    required this.label,
    required this.controller,
    required this.color,
    required this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => ToolPanel(
    title: label,
    trailing: Text(
      '${controller.text.split('\n').length} 行',
      style: Theme.of(context).textTheme.bodySmall,
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: 20,
      maxLines: 28,
      style: const TextStyle(fontFamily: 'SF Mono', fontSize: 12, height: 1.55),
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
      ),
    ),
  );
}

class _DiffSummary extends StatelessWidget {
  const _DiffSummary({required this.result});
  final TextDiffResult result;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        result.hasChanges ? '发现变化，已按行标记。' : '两段文本完全一致。',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(
          children: [
            if (result.addedCount > 0)
              Expanded(
                flex: result.addedCount,
                child: Container(height: 7, color: const Color(0xFF65D9C1)),
              ),
            if (result.modifiedCount > 0)
              Expanded(
                flex: result.modifiedCount,
                child: Container(height: 7, color: const Color(0xFFFFB86B)),
              ),
            if (result.removedCount > 0)
              Expanded(
                flex: result.removedCount,
                child: Container(height: 7, color: const Color(0xFFFF8F92)),
              ),
          ],
        ),
      ),
    ],
  );
}
