import 'package:flutter/material.dart';

class ScreenUtil {

  static Size getScreenSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size;
  }
}
