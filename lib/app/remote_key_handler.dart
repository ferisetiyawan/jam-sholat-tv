import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/settings/config_menu_screen.dart';

/// App-wide TV-remote key handling.
///
/// Place this in the `MaterialApp.builder` (above the Navigator) so it receives
/// key events from every route, and pass the app's `navigatorKey` so it can
/// push/pop the config menu itself:
///
/// - **Long-press OK/Select** (≥ 1.2s) — opens the config menu, or closes it
///   if already open.
/// - **Menu key** — same toggle, instantly.
///
/// A quick press of OK is ignored, so the display stays invisible to viewers.
class RemoteKeyDetector extends StatefulWidget {
  const RemoteKeyDetector({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// The hold duration that distinguishes "long-press" from a quick OK press.
  static const Duration holdDuration = Duration(milliseconds: 1200);

  @override
  State<RemoteKeyDetector> createState() => _RemoteKeyDetectorState();
}

class _RemoteKeyDetectorState extends State<RemoteKeyDetector> {
  static final Set<LogicalKeyboardKey> _selectKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  Timer? _holdTimer;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final bool isSelect = _selectKeys.contains(event.logicalKey);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
        _toggleConfigMenu();
        return KeyEventResult.handled;
      }
      if (isSelect) {
        _holdTimer ??= Timer(RemoteKeyDetector.holdDuration, _toggleConfigMenu);
      }
    } else if (event is KeyUpEvent && isSelect) {
      _cancelHold();
    }

    return KeyEventResult.ignored;
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _toggleConfigMenu() {
    _cancelHold();
    final NavigatorState? navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const ConfigMenuScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }
}
