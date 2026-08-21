import 'package:flutter/material.dart';

import '../../domain/sql_log_converter.dart';
import '../../platform/clipboard_bridge.dart';
import '../tool_workspace.dart';
import 'tool_primitives.dart';

class SqlTool extends StatefulWidget {
  const SqlTool({super.key});

  @override
  State<SqlTool> createState() => _SqlToolState();
}

class _SqlToolState extends State<SqlTool> {
  final _input = TextEditingController(
    text:
        'Preparing: SELECT * FROM users WHERE id = ? AND active = ?\n'
        'Parameters: 42(Integer), true(Boolean)',
  );
  SqlLogConversionResult _result = SqlLogConversionResult.empty;
  SqlLogDialect _dialect = SqlLogDialect.mysql;

  @override
  void initState() {
    super.initState();
    _convert();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _convert() {
    setState(() {
      _result = const SqlLogConverter().convert(_input.text, dialect: _dialect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToolCanvas(
      header: ToolActions(
        children: [
          DropdownButton<SqlLogDialect>(
            value: _dialect,
            items: [
              for (final dialect in SqlLogDialect.values)
                DropdownMenuItem(value: dialect, child: Text(dialect.label)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _dialect = value);
              _convert();
            },
          ),
          const SizedBox(width: 2),
          FilledButton.icon(
            onPressed: _convert,
            icon: const Icon(Icons.play_arrow_rounded, size: 17),
            label: const Text('还原 SQL'),
          ),
          IconButton(
            tooltip: '导入日志',
            onPressed: () async {
              final text = await importText();
              if (text != null) {
                _input.text = text;
                _convert();
              }
            },
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: '导出 SQL',
            onPressed: _result.output.isEmpty
                ? null
                : () => exportText(
                    _result.output,
                    suggestedName: 'restored.sql',
                    extension: 'sql',
                  ),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      children: [
        ToolPanel(
          title: '日志输入',
          child: ClipboardTextField(
            controller: _input,
            onChanged: (_) => _convert(),
            minLines: 8,
            maxLines: 12,
            style: const TextStyle(
              fontFamily: 'SF Mono',
              fontSize: 12,
              height: 1.55,
            ),
            decoration: const InputDecoration(
              hintText: '输入 Preparing / Parameters 日志',
            ),
          ),
        ),
        const SizedBox(height: 14),
        ToolPanel(
          title: '还原结果',
          trailing: Text(
            '${_result.statements.length} 条语句',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          child: _result.output.isEmpty
              ? Text(
                  _result.diagnostics.isEmpty
                      ? '等待输入 SQL 日志'
                      : _result.diagnostics.join('\n'),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                )
              : SelectableText(
                  _result.output,
                  style: const TextStyle(
                    fontFamily: 'SF Mono',
                    fontSize: 12,
                    height: 1.65,
                  ),
                ),
        ),
        if (_result.warningCount > 0) ...[
          const SizedBox(height: 14),
          ToolPanel(
            title: '诊断',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final warning in _result.allWarnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      warning,
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
