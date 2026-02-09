import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/liquid_theme.dart';

/// System Terminal Log Widget - Real API Logs + Mock Fallback
class TerminalLogWidget extends StatefulWidget {
  final double height;
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final List<String>? customLogs; // Real API logs if available

  const TerminalLogWidget({
    super.key,
    this.height = 150,
    this.isCollapsed = false,
    this.onToggle,
    this.customLogs,
  });

  @override
  State<TerminalLogWidget> createState() => _TerminalLogWidgetState();
}

class _TerminalLogWidgetState extends State<TerminalLogWidget> {
  final List<LogEntry> _mockLogs = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _logTimer;
  int _logIndex = 0;

  final List<String> _mockLogMessages = [
    '[SYSTEM] Finsight backend ready...',
    '[BACKBOARD] Knowledge graph initialized',
    '[ML] Document classifier loaded',
    '[VALIDATE] Validation engine online',
    '[SYSTEM] Awaiting document upload...',
  ];

  @override
  void initState() {
    super.initState();
    // Only start mock stream if no custom logs
    if (widget.customLogs == null || widget.customLogs!.isEmpty) {
      _startMockStream();
    }
  }

  @override
  void didUpdateWidget(TerminalLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when new logs arrive
    if (widget.customLogs != null && widget.customLogs!.length != (oldWidget.customLogs?.length ?? 0)) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startMockStream() {
    for (int i = 0; i < _mockLogMessages.length; i++) {
      _mockLogs.add(LogEntry(
        timestamp: DateTime.now().toString().substring(11, 19),
        message: _mockLogMessages[i],
      ));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getLogColor(String message) {
    if (message.contains('[ERROR]') || message.contains('FAIL') || message.contains('failed')) return LiquidTheme.neonPink;
    if (message.contains('[PASS]') || message.contains('Success') || message.contains('✓')) return LiquidTheme.neonGreen;
    if (message.contains('[API]') || message.contains('[UPLOAD]')) return LiquidTheme.neonCyan;
    if (message.contains('[ML]') || message.contains('[LEARN]') || message.contains('Classification')) return LiquidTheme.neonPurple;
    if (message.contains('[QUEUE]') || message.contains('[CORRECT]')) return LiquidTheme.neonYellow;
    if (message.contains('[METRICS]') || message.contains('[CLUSTERS]')) return LiquidTheme.neonGreen;
    return LiquidTheme.textMuted;
  }

  List<LogEntry> get _displayLogs {
    if (widget.customLogs != null && widget.customLogs!.isNotEmpty) {
      return widget.customLogs!.map((msg) {
        // Extract timestamp if present in format [HH:MM:SS]
        final timestampMatch = RegExp(r'\[(\d{2}:\d{2}:\d{2})\]').firstMatch(msg);
        if (timestampMatch != null) {
          return LogEntry(
            timestamp: timestampMatch.group(1)!,
            message: msg.substring(timestampMatch.end).trim(),
          );
        }
        return LogEntry(timestamp: '', message: msg);
      }).toList();
    }
    return _mockLogs;
  }

  @override
  Widget build(BuildContext context) {
    final logs = _displayLogs;
    final hasRealLogs = widget.customLogs != null && widget.customLogs!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: widget.isCollapsed ? 36 : widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF050508),
        border: Border(top: BorderSide(color: LiquidTheme.neonCyan.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0a0e17),
                border: Border(bottom: BorderSide(color: LiquidTheme.glassBorder)),
              ),
              child: Row(
                children: [
                  Icon(widget.isCollapsed ? Icons.terminal : Icons.keyboard_arrow_down, color: LiquidTheme.neonCyan, size: 14),
                  const SizedBox(width: 6),
                  Text('SYSTEM TERMINAL', style: LiquidTheme.monoData(size: 9, color: LiquidTheme.neonCyan, weight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: hasRealLogs ? LiquidTheme.neonGreen : LiquidTheme.neonYellow,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: (hasRealLogs ? LiquidTheme.neonGreen : LiquidTheme.neonYellow).withOpacity(0.5), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(hasRealLogs ? 'LIVE API' : 'STANDBY', style: LiquidTheme.monoData(size: 8, color: hasRealLogs ? LiquidTheme.neonGreen : LiquidTheme.neonYellow)),
                  const Spacer(),
                  Text('${logs.length} events', style: LiquidTheme.monoData(size: 8, color: LiquidTheme.textMuted)),
                ],
              ),
            ),
          ),
          
          if (!widget.isCollapsed)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final color = _getLogColor(log.message);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (log.timestamp.isNotEmpty)
                          Text('[${log.timestamp}] ', style: LiquidTheme.monoData(size: 10, color: LiquidTheme.textMuted)),
                        Expanded(
                          child: Text(
                            log.message, 
                            style: LiquidTheme.monoData(size: 10, color: color),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LogEntry {
  final String timestamp;
  final String message;

  LogEntry({required this.timestamp, required this.message});
}
