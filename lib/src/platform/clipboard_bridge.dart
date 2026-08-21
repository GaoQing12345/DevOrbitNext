import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps the last Flutter editor selection alive while a clipboard manager
/// temporarily takes focus. This is intentionally editor-agnostic so every
/// tool gets the same Cmd/Ctrl+V and iCopy behavior.
class OrbitClipboardBridge {
  OrbitClipboardBridge._();

  static final instance = OrbitClipboardBridge._();
  static const _channel = MethodChannel('dev_orbit/clipboard');

  final _entries = <_ClipboardEntry>[];
  _ClipboardEntry? _lastFocused;
  _ClipboardSnapshot? _snapshot;
  Timer? _pollTimer;
  int _nextSession = 0;
  int _captureGeneration = 0;
  String? _lastObservedText;
  bool _started = false;
  int? _pendingNativeSession;
  String? _pendingNativeText;
  bool _pendingNativeChange = false;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  void start() {
    if (_started || !_isDesktop) return;
    _started = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  void register({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool editable,
  }) {
    start();
    final entry = _ClipboardEntry(
      controller: controller,
      focusNode: focusNode,
      editable: editable,
    );
    _entries.add(entry);
    focusNode.addListener(() => _onFocusChanged(entry));
    controller.addListener(() => _onContentChanged(entry));
  }

  void unregister(TextEditingController controller, FocusNode focusNode) {
    final index = _entries.indexWhere(
      (entry) =>
          identical(entry.controller, controller) &&
          identical(entry.focusNode, focusNode),
    );
    if (index < 0) return;
    final entry = _entries.removeAt(index);
    if (identical(_lastFocused, entry)) _lastFocused = null;
    if (identical(_snapshot?.entry, entry)) _cancelSnapshot();
  }

  void onWindowBlur() {
    final target = _focusedEntry() ?? _lastFocused;
    if (target == null || !target.editable) return;
    _capture(target);
  }

  void _onFocusChanged(_ClipboardEntry entry) {
    if (!entry.focusNode.hasFocus || !entry.editable) return;
    _lastFocused = entry;
    // A click back into Orbit means the user has started a new edit session.
    if (_snapshot != null && !identical(_snapshot!.entry, entry)) {
      _cancelSnapshot();
    }
  }

  void _onContentChanged(_ClipboardEntry entry) {
    final snapshot = _snapshot;
    if (snapshot != null && identical(snapshot.entry, entry)) {
      // Any normal typing invalidates the stale selection we captured before
      // the external clipboard app took focus.
      if (entry.controller.text != snapshot.text) _cancelSnapshot();
    }
  }

  _ClipboardEntry? _focusedEntry() {
    for (final entry in _entries) {
      if (entry.editable && entry.focusNode.hasFocus) return entry;
    }
    return null;
  }

  Future<void> _capture(_ClipboardEntry entry) async {
    _cancelSnapshot();
    final generation = ++_captureGeneration;
    final session = ++_nextSession;
    // Arm native capture before reading the baseline. Clipboard managers can
    // publish their selected item immediately after they take focus.
    unawaited(_armNative(session));
    final baseline = await _readClipboard();
    if (generation != _captureGeneration || !_entries.contains(entry)) {
      unawaited(_discardNative(session));
      return;
    }
    final snapshot = _ClipboardSnapshot(
      entry: entry,
      text: entry.controller.text,
      selection: entry.controller.selection,
      baselineClipboard: baseline,
      session: session,
      createdAt: DateTime.now(),
    );
    _snapshot = snapshot;
    _lastObservedText = baseline;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 90),
      (_) => unawaited(_pollClipboard(snapshot)),
    );
    final pendingText = _pendingNativeSession == session
        ? _pendingNativeText
        : null;
    final pendingChange =
        _pendingNativeSession == session && _pendingNativeChange;
    _pendingNativeSession = null;
    _pendingNativeText = null;
    _pendingNativeChange = false;
    if (pendingText != null) {
      await _insert(snapshot, pendingText);
    } else if (pendingChange) {
      unawaited(_pollClipboard(snapshot));
    }
  }

  Future<void> _pollClipboard(_ClipboardSnapshot snapshot) async {
    if (!identical(_snapshot, snapshot)) return;
    if (DateTime.now().difference(snapshot.createdAt) >
        const Duration(minutes: 3)) {
      _cancelSnapshot();
      return;
    }
    final text = await _readClipboard();
    if (!identical(_snapshot, snapshot) || text == null) return;
    if (text == snapshot.baselineClipboard || text == _lastObservedText) {
      return;
    }
    _lastObservedText = text;
    await _insert(snapshot, text);
  }

  Future<void> _insert(_ClipboardSnapshot snapshot, String text) async {
    if (!identical(_snapshot, snapshot) || text.isEmpty) return;
    final entry = snapshot.entry;
    if (!_entries.contains(entry) || !entry.editable) {
      _cancelSnapshot();
      return;
    }
    final value = entry.controller.value;
    if (value.text != snapshot.text) {
      _cancelSnapshot();
      return;
    }
    final selection = snapshot.selection;
    final start = selection.start.clamp(0, value.text.length).toInt();
    final end = selection.end.clamp(0, value.text.length).toInt();
    entry.controller.value = value.copyWith(
      text: value.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );
    entry.focusNode.requestFocus();
    _cancelSnapshot();
  }

  Future<void> _armNative(int session) async {
    try {
      await _channel.invokeMethod<void>('armPasteCapture', {
        'sessionId': session,
      });
    } on MissingPluginException {
      // Linux and older builds use the polling fallback.
    } on PlatformException {
      // A clipboard provider must never make an editor unusable.
    }
  }

  Future<void> _discardNative(int session) async {
    try {
      await _channel.invokeMethod<void>('discardPendingPasteText', {
        'sessionId': session,
      });
    } on Object {
      // Optional native bridge.
    }
  }

  Future<String?> _readClipboard() async {
    for (final delay in const [
      Duration.zero,
      Duration(milliseconds: 12),
      Duration(milliseconds: 30),
      Duration(milliseconds: 70),
    ]) {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      try {
        final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
        if (text != null) return text;
      } on PlatformException {
        // Clipboard managers can briefly own the clipboard while publishing
        // multiple formats. Retry without surfacing a false error to users.
      }
    }
    return null;
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'clipboardChanged') return;
    final args = call.arguments;
    if (args is! Map) return;
    final rawSession = args['sessionId'];
    final session = rawSession is num ? rawSession.toInt() : null;
    if (session == null) return;
    final text = args['text'] is String ? args['text'] as String : null;
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.session != session) {
      _pendingNativeSession = session;
      _pendingNativeText = text;
      _pendingNativeChange = true;
      return;
    }
    if (text != null && text.isNotEmpty) {
      await _insert(snapshot, text);
    } else {
      unawaited(_pollClipboard(snapshot));
    }
  }

  void _cancelSnapshot() {
    _captureGeneration++;
    final snapshot = _snapshot;
    _snapshot = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _lastObservedText = null;
    if (snapshot != null) unawaited(_discardNative(snapshot.session));
  }
}

class _ClipboardEntry {
  const _ClipboardEntry({
    required this.controller,
    required this.focusNode,
    required this.editable,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editable;
}

class _ClipboardSnapshot {
  const _ClipboardSnapshot({
    required this.entry,
    required this.text,
    required this.selection,
    required this.baselineClipboard,
    required this.session,
    required this.createdAt,
  });

  final _ClipboardEntry entry;
  final String text;
  final TextSelection selection;
  final String? baselineClipboard;
  final int session;
  final DateTime createdAt;
}

class ClipboardTextField extends StatefulWidget {
  const ClipboardTextField({
    super.key,
    required this.controller,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.style,
    this.decoration,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool obscureText;

  @override
  State<ClipboardTextField> createState() => _ClipboardTextFieldState();
}

class _ClipboardTextFieldState extends State<ClipboardTextField> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    OrbitClipboardBridge.instance.register(
      controller: widget.controller,
      focusNode: _focusNode,
      editable: !widget.readOnly,
    );
  }

  @override
  void dispose() {
    OrbitClipboardBridge.instance.unregister(widget.controller, _focusNode);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: widget.expands,
      style: widget.style,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
    );
  }
}
