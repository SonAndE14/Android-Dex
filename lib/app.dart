import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/boot_screen.dart';
import 'screens/home_screen.dart';

class AndroidDexApp extends StatelessWidget {
  const AndroidDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Android DEX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const BootScreen(),
    );
  }
}
