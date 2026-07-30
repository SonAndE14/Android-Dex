import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Android DEX';
  static const String appVersion = 'DEX-STABLE-104-SINGLE';

  static const String adbExecutable = 'adb.exe';
  static const String scrcpyExecutable = 'scrcpy.exe';
  static const String jarName = 'androiddex.jar';
  static const String apkName = 'AndroidDex.apk';

  static const int jarServerPort = 50123;
  static const int apkServerPort = 50124;
  static const int mediaServerPort = 50125;
  static const int notificationServerPort = 50126;

  static const double bootProgressTotal = 1.0;

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration reconnectionInterval = Duration(seconds: 5);

  static const Color primaryColor = Color(0xFF0078D4);
  static const Color backgroundColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF252526);
  static const Color cardColor = Color(0xFF2D2D2D);
  static const Color accentColor = Color(0xFF0078D4);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
}
