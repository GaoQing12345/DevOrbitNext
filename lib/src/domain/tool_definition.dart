enum ToolId { json, translator, diff, timestamp, sql }

enum OrbitMode { hidden, launcher, tool, settings }

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.slot,
    required this.accent,
  });

  final ToolId id;
  final String name;
  final String shortName;
  final String description;
  final int slot;
  final int accent;
}

const toolDefinitions = <ToolDefinition>[
  ToolDefinition(
    id: ToolId.json,
    name: 'JSON Studio',
    shortName: 'JSON',
    description: '校验、修复、格式化与压缩 JSON',
    slot: 0,
    accent: 0xFF65D9C1,
  ),
  ToolDefinition(
    id: ToolId.translator,
    name: '翻译',
    shortName: '译',
    description: '通过 DeepL API 翻译文本',
    slot: 1,
    accent: 0xFF79A9FF,
  ),
  ToolDefinition(
    id: ToolId.diff,
    name: '文本比对',
    shortName: 'Diff',
    description: '并排查看两段文本的变化',
    slot: 2,
    accent: 0xFFFFB86B,
  ),
  ToolDefinition(
    id: ToolId.timestamp,
    name: '时间戳',
    shortName: 'Time',
    description: '秒、毫秒与本地时间互转',
    slot: 3,
    accent: 0xFFE68B9A,
  ),
  ToolDefinition(
    id: ToolId.sql,
    name: 'SQL 日志',
    shortName: 'SQL',
    description: '还原 MyBatis Preparing / Parameters 日志',
    slot: 4,
    accent: 0xFFBCA0FF,
  ),
];

ToolDefinition definitionFor(ToolId id) =>
    toolDefinitions.firstWhere((tool) => tool.id == id);
