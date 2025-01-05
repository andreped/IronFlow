import 'package:flutter/material.dart';

class ClampingScrollController extends ScrollController {
  @override
  void jumpTo(double value) {
    if (hasClients) {
      final double maxScrollExtent = position.maxScrollExtent;
      final double minScrollExtent = position.minScrollExtent;
      final double clampedValue = value.clamp(minScrollExtent, maxScrollExtent);
      super.jumpTo(clampedValue);
    }
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    if (hasClients) {
      final double maxScrollExtent = position.maxScrollExtent;
      final double minScrollExtent = position.minScrollExtent;
      final double clampedOffset =
          offset.clamp(minScrollExtent, maxScrollExtent);
      return super.animateTo(clampedOffset, duration: duration, curve: curve);
    }
    return Future.value();
  }
}
