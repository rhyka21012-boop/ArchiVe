import 'package:flutter/material.dart';

class CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;

    // BottomNavigationBarの高さを推定（内側 Scaffold には BottomNav が無いので 0 になる前提）
    final bottomNavBarHeight =
        scaffoldSize.height - scaffoldGeometry.contentBottom;

    final double dx = scaffoldSize.width - fabSize.width - 16;
    // body 底辺から 24dp 上に配置（標準 FAB マージン）
    final double dy =
        scaffoldSize.height - bottomNavBarHeight - fabSize.height - 24;

    return Offset(dx, dy);
  }
}
