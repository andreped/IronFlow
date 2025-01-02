import 'package:flutter/material.dart';

void onScroll(
    ScrollController verticalScrollController, Function loadNextChunk) {
  if (verticalScrollController.position.pixels >=
      verticalScrollController.position.maxScrollExtent - 200) {
    loadNextChunk();
  }
}

void onHorizontalScroll(
  ScrollController horizontalScrollController,
  List<ScrollController> rowControllers,
  bool isSyncing,
  ScrollController? activeRowController,
) {
  if (isSyncing) return;
  for (var rowController in rowControllers) {
    if (rowController != activeRowController && rowController.hasClients) {
      rowController.jumpTo(horizontalScrollController.offset);
    }
  }
}
