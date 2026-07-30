import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';
import '../models/device_model.dart';
import '../services/adb_service.dart';

class ConnectionStateProvider extends ChangeNotifier {
  final AdbService _adb = AdbService();
  ConnectionState _state = const ConnectionState();
  WebSocketChannel? _apkChannel;
  ServerSocket? _jarServer;
  Timer? _reconnectionTimer;

  ConnectionState get state => _state;

  void reset() {
    _state = const ConnectionState();
    _apkChannel?.sink.close();
    _jarServer?.close();
    _reconnectionTimer?.cancel();
    notifyListeners();
  }

  Future<void> startConnection(AndroidDevice device) async {
    reset();
    _adb.setDevice(device);

    try {
      await _updateState(statusMessage: 'Starting ADB server...', jarProgress: 0.1);
      final startResult = await _adb.startServer();
      if (!startResult.success) {
        await _updateState(
          error: 'Failed to start ADB server: ${startResult.output}',
          isError: true,
        );
        return;
      }

      await _updateState(statusMessage: 'Connecting to device...', jarProgress: 0.2);
      if (device.isWifi) {
        final connectResult = await _adb.connect(device.ipAddress ?? '', port: device.port ?? 5555);
        if (!connectResult.success) {
          await _updateState(
            error: 'Failed to connect: ${connectResult.output}',
            isError: true,
          );
          return;
        }
      }

      await _updateState(statusMessage: 'Starting JAR engine...', jarProgress: 0.4);
      await _adb.killJarProcess();
      final pushResult = await _adb.push(
        AppConstants.jarName,
        '/data/local/tmp/',
      );

      await _updateState(statusMessage: 'Launching JAR runtime...', jarProgress: 0.6);
      await _startJarServer();

      await _updateState(statusMessage: 'Checking APK installation...', jarProgress: 0.7, apkProgress: 0.3);
      final isInstalled = await _adb.isPackageInstalled('com.androiddex.app');
      if (!isInstalled) {
        await _adb.installApk(AppConstants.apkName);
      }

      await _updateState(statusMessage: 'Starting APK services...', jarProgress: 0.8, apkProgress: 0.6);
      await _startApkWebSocket();

      await _updateState(
        statusMessage: 'System synchronized!',
        jarProgress: 1.0,
        apkProgress: 1.0,
        totalProgress: 1.0,
        isBootComplete: true,
        jarReady: true,
        apkReady: true,
        jarConnected: true,
        apkConnected: true,
      );
    } catch (e) {
      await _updateState(
        error: 'Connection failed: $e',
        isError: true,
      );
    }
  }

  Future<void> _startJarServer() async {
    try {
      _jarServer = await ServerSocket.bind('127.0.0.1', AppConstants.jarServerPort);
      _jarServer!.listen((socket) {
        socket.cast<List<int>>().transform(utf8.decoder).listen((data) {
          try {
            final msg = jsonDecode(data);
            if (msg is Map && msg['type'] == 'jar.hello') {
              _updateState(jarConnected: true, jarReady: true);
            }
          } catch (_) {}
        });
      });
    } catch (e) {
      debugPrint('JAR server error: $e');
    }
  }

  Future<void> _startApkWebSocket() async {
    try {
      final url = Uri.parse('ws://127.0.0.1:${AppConstants.apkServerPort}');
      _apkChannel = WebSocketChannel.connect(url);

      await _apkChannel!.ready;
      _updateState(apkConnected: true);

      _apkChannel!.stream.listen((data) {
        try {
          final msg = jsonDecode(data as String);
          if (msg is Map) {
            if (msg['type'] == 'apk.hello') {
              _updateState(apkReady: true);
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('APK WebSocket error: $e');
    }
  }

  Future<void> _updateState({
    bool? jarConnected,
    bool? apkConnected,
    bool? jarReady,
    bool? apkReady,
    bool? isBootComplete,
    double? jarProgress,
    double? apkProgress,
    double? totalProgress,
    String? statusMessage,
    String? error,
    bool? isError,
  }) async {
    _state = _state.copyWith(
      jarConnected: jarConnected,
      apkConnected: apkConnected,
      jarReady: jarReady,
      apkReady: apkReady,
      isBootComplete: isBootComplete,
      jarProgress: jarProgress,
      apkProgress: apkProgress,
      totalProgress: totalProgress,
      statusMessage: statusMessage,
      error: error,
      isError: isError,
    );
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _reconnectionTimer?.cancel();
    _apkChannel?.sink.close();
    _jarServer?.close();
    super.dispose();
  }
}
