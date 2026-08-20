import 'package:flutter/material.dart';

import '../../domain/json_transformer.dart';
import '../tool_workspace.dart';
import 'tool_primitives.dart';

class JsonTool extends StatefulWidget {
  const JsonTool({super.key});

  @override
  State<JsonTool> createState() => _JsonToolState();
}

class _JsonToolState extends State<JsonTool> {
  final _input = TextEditingController(
    text: '{\n  "orbit": true,\n  "tools": ["json", "diff"]\n}',
  );
  final _output = TextEditingController();
  JsonIssue? _issue;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _output.dispose();
    super.dispose();
  }

  Future<void> _run(JsonTransformMode mode) async {
    setState(() {
      _busy = true;
    });
    final result = await const JsonTransformer().run(
      _input.text,
      mode,
      indentSize: 2,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _issue = result.issue;
      if (result.output != null) _output.text = result.output!;
    });
  }

  Future<void> _import() async {
    final text = await importText(extensions: const ['json', 'txt']);
    if (text != null) setState(() => _input.text = text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToolCanvas(
      header: ToolActions(
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(JsonTransformMode.format),
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text('格式化'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(JsonTransformMode.compact),
            icon: const Icon(Icons.compress_rounded, size: 16),
            label: const Text('压缩'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(JsonTransformMode.validate),
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('校验'),
          ),
          IconButton(
            tooltip: '导入 JSON 文件',
            onPressed: _import,
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: '导出结果',
            onPressed: _output.text.isEmpty
                ? null
                : () => exportText(
                    _output.text,
                    suggestedName: 'formatted.json',
                    extension: 'json',
                  ),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final vertical = constraints.maxWidth < 900;
            final input = ToolPanel(
              title: '输入',
              trailing: Text(
                '${_input.text.length} 字符',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              child: TextField(
                controller: _input,
                minLines: vertical ? 12 : 22,
                maxLines: vertical ? 18 : 30,
                expands: false,
                style: const TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 12,
                  height: 1.55,
                ),
                decoration: const InputDecoration(
                  hintText: '在这里输入 JSON，不会读取系统剪贴板',
                ),
              ),
            );
            final output = ToolPanel(
              title: '输出',
              trailing: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _issue == null ? '就绪' : '需要修复',
                      style: TextStyle(
                        color: _issue == null ? scheme.primary : scheme.error,
                        fontSize: 11,
                      ),
                    ),
              child: TextField(
                controller: _output,
                readOnly: true,
                minLines: vertical ? 12 : 22,
                maxLines: vertical ? 18 : 30,
                style: const TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 12,
                  height: 1.55,
                ),
                decoration: const InputDecoration(hintText: '格式化结果会显示在这里'),
              ),
            );
            return vertical
                ? Column(children: [input, const SizedBox(height: 14), output])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: input),
                      const SizedBox(width: 14),
                      Expanded(child: output),
                    ],
                  );
          },
        ),
        if (_issue != null) ...[
          const SizedBox(height: 14),
          ToolPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '第 ${_issue!.line} 行，第 ${_issue!.column} 列：${_issue!.message}',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
