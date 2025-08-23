import 'package:flutter/material.dart';

class CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final scaffoldSize = scaffoldGeometry.scaffoldSize;

    // BottomNavigationBarの高さを推定
    final bottomNavBarHeight =
        scaffoldSize.height - scaffoldGeometry.contentBottom;

    final double dx = scaffoldSize.width - fabSize.width - 16;
    final double dy =
        scaffoldSize.height - bottomNavBarHeight - fabSize.height - 16 - 150;

    return Offset(dx, dy);
  }
}
