import 'package:flutter/material.dart';

import '../../domain/deepl_translation_client.dart';
import '../../domain/translation_language.dart';
import 'tool_primitives.dart';

class TranslatorTool extends StatefulWidget {
  const TranslatorTool({super.key});
  @override
  State<TranslatorTool> createState() => _TranslatorToolState();
}

class _TranslatorToolState extends State<TranslatorTool> {
  final _source = TextEditingController(
    text: 'Build tools that stay out of your way.',
  );
  final _apiKey = TextEditingController();
  final _target = ValueNotifier<String>('ZH-HANS');
  final _client = DeepLTranslationClient();
  String _output = '';
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _source.dispose();
    _apiKey.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    if (_apiKey.text.trim().isEmpty) {
      setState(() => _error = '请先输入 DeepL API Key。本项目不会把 Key 写入系统剪贴板。');
      return;
    }
    if (_source.text.trim().isEmpty) {
      setState(() => _error = '请输入要翻译的文本。');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _client.translate(
        apiKey: _apiKey.text.trim(),
        text: _source.text,
        targetLanguage: _target.value,
      );
      if (mounted) setState(() => _output = result.text);
    } on TranslationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ToolCanvas(
    children: [
      ToolPanel(
        title: 'DeepL API',
        child: TextField(
          controller: _apiKey,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            prefixIcon: Icon(Icons.key_outlined),
            helperText: '仅用于当前请求，不写入系统剪贴板或日志',
          ),
        ),
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final source = ToolPanel(
            title: '原文',
            child: TextField(
              controller: _source,
              minLines: 12,
              maxLines: 18,
              decoration: const InputDecoration(hintText: '输入文本'),
            ),
          );
          final result = ToolPanel(
            title: '译文',
            trailing: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            child: SelectableText(
              _output.isEmpty ? '翻译结果会显示在这里' : _output,
              style: TextStyle(
                color: _output.isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          );
          return constraints.maxWidth < 760
              ? Column(children: [source, const SizedBox(height: 14), result])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: source),
                    const SizedBox(width: 14),
                    Expanded(child: result),
                  ],
                );
        },
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _target,
            builder: (context, value, _) => DropdownButton<String>(
              value: value,
              items: [
                for (final language in translationLanguages)
                  DropdownMenuItem(
                    value: language.code,
                    child: Text(language.label),
                  ),
              ],
              onChanged: (next) {
                if (next != null) _target.value = next;
              },
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _loading ? null : _translate,
            icon: const Icon(Icons.translate_rounded, size: 17),
            label: const Text('开始翻译'),
          ),
        ],
      ),
      if (_error != null) ...[
        const SizedBox(height: 14),
        ToolPanel(
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xFFFF8F92)),
          ),
        ),
      ],
    ],
  );
}
