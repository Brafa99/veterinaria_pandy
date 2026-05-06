import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) =>
      width(context) < 600;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 1100;

  static bool isDesktop(BuildContext context) =>
      width(context) >= 1100;

  static int gridCount(BuildContext context) {
    final w = width(context);
    if (w < 600) return 2;
    if (w < 1100) return 3;
    return 4;
  }

  static double padding(BuildContext context) {
    if (isMobile(context)) return 10;
    if (isTablet(context)) return 16;
    return 20;
  }
}