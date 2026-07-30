import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/app_state.dart';
import 'providers/connection_state.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle(AppConstants.appName);
    await windowManager.setMinimumSize(const Size(1024, 680));
    await windowManager.setSize(const Size(1280, 800));
    await windowManager.center();
    await windowManager.show();
    await windowManager.setPreventClose(true);
  });

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionStateProvider()),
      ],
      child: const AndroidDexApp(),
    ),
  );
}
