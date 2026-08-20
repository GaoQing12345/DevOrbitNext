import 'package:flutter/material.dart';

import '../../domain/timestamp_converter.dart';
import 'tool_primitives.dart';

class TimestampTool extends StatefulWidget {
  const TimestampTool({super.key});
  @override
  State<TimestampTool> createState() => _TimestampToolState();
}

class _TimestampToolState extends State<TimestampTool> {
  final _timestamp = TextEditingController(
    text: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  final _date = TextEditingController(
    text: TimestampConverter.formatDateTime(DateTime.now()),
  );
  String? _timestampResult;
  String? _dateResult;
  String? _error;

  @override
  void dispose() {
    _timestamp.dispose();
    _date.dispose();
    super.dispose();
  }

  void _fromTimestamp() {
    try {
      final result = TimestampConverter.parseTimestamp(_timestamp.text);
      setState(() {
        _timestampResult = TimestampConverter.formatDateTime(result.dateTime);
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _fromDate() {
    try {
      final result = TimestampConverter.convertDateTime(
        TimestampConverter.parseDateTime(_date.text),
      );
      setState(() {
        _dateResult = '${result.seconds} 秒  ·  ${result.milliseconds} 毫秒';
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => ToolCanvas(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final timestampPanel = ToolPanel(
            title: '时间戳 → 本地时间',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _timestamp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '秒或毫秒时间戳'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _fromTimestamp,
                  icon: const Icon(Icons.transform_rounded, size: 17),
                  label: const Text('转换'),
                ),
                if (_timestampResult != null) ...[
                  const SizedBox(height: 14),
                  _ResultText(text: _timestampResult!),
                ],
              ],
            ),
          );
          final datePanel = ToolPanel(
            title: '本地时间 → 时间戳',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _date,
                  decoration: const InputDecoration(
                    labelText: 'yyyy-MM-dd HH:mm:ss.SSS',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _fromDate,
                  icon: const Icon(Icons.schedule_send_rounded, size: 17),
                  label: const Text('转换'),
                ),
                if (_dateResult != null) ...[
                  const SizedBox(height: 14),
                  _ResultText(text: _dateResult!),
                ],
              ],
            ),
          );
          return constraints.maxWidth < 760
              ? Column(
                  children: [
                    timestampPanel,
                    const SizedBox(height: 14),
                    datePanel,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: timestampPanel),
                    const SizedBox(width: 14),
                    Expanded(child: datePanel),
                  ],
                );
        },
      ),
      if (_error != null) ...[
        const SizedBox(height: 14),
        ToolPanel(
          child: Text(_error!, style: TextStyle(color: Color(0xFFFF8F92))),
        ),
      ],
    ],
  );
}

class _ResultText extends StatelessWidget {
  const _ResultText({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: TextStyle(
      fontFamily: 'SF Mono',
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
  );
}
