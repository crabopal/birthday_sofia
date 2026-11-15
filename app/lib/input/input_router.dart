import 'package:flutter/services.dart';

/// Central place for D-pad / gamepad routing.
class InputRouter {
  InputRouter._();

  static bool isSelect(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA;
  }

  static bool isBack(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB;
  }

  static bool isJump(KeyEvent event) {
    return isSelect(event) ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.gameButtonX ||
        event.logicalKey == LogicalKeyboardKey.gameButtonY;
  }

  static bool isLeft(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA;
  }

  static bool isRight(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD;
  }

  static bool isDirection(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight;
  }
}
