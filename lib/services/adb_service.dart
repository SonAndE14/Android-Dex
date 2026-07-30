import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';
import '../models/device_model.dart';

class AdbResult {
  final bool success;
  final String output;
  AdbResult({required this.success, required this.output});
}

class AdbService {
  static final AdbService _instance = AdbService._();
  factory AdbService() => _instance;
  AdbService._();

  String? _adbPath;
  String? _deviceId;

  String get adbPath => _adbPath ?? 'adb.exe';

  String get adbArgs {
    if (_deviceId == null || _deviceId == '-d') return '-d';
    return '-s $_deviceId';
  }

  AndroidDevice? _currentDevice;
  AndroidDevice? get currentDevice => _currentDevice;

  Future<bool> initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _adbPath = '${dir.path}\\${AppConstants.adbExecutable}';
      if (!File(_adbPath!).existsSync()) {
        _adbPath = 'adb.exe';
      }
      return true;
    } catch (e) {
      _adbPath = 'adb.exe';
      return true;
    }
  }

  Future<AdbResult> run(List<String> args, {Duration? timeout}) async {
    try {
      final process = await Process.start(adbPath, args, runInShell: true);
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      final exitCode = process.exitTimeOut(timeout ?? const Duration(seconds: 30));
      return AdbResult(
        success: exitCode == 0,
        output: (stdout + stderr).trim(),
      );
    } catch (e) {
      return AdbResult(success: false, output: e.toString());
    }
  }

  Future<AdbResult> runOnDevice(List<String> args, {Duration? timeout}) async {
    final fullArgs = [adbArgs, ...args];
    return run(fullArgs, timeout: timeout);
  }

  Future<AdbResult> startServer() async {
    return run(['start-server']);
  }

  Future<AdbResult> killServer() async {
    return run(['kill-server']);
  }

  Future<List<AndroidDevice>> getDevices() async {
    final result = await run(['devices']);
    if (!result.success) return [];

    final devices = <AndroidDevice>[];
    final lines = result.output.split('\n');
    for (final line in lines) {
      if (line.contains('device') && !line.contains('List of devices')) {
        devices.add(AndroidDevice.fromAdbDevicesLine(line));
      }
    }
    return devices;
  }

  Future<AdbResult> connect(String ip, {int port = 5555}) async {
    return run(['connect', '$ip:$port']);
  }

  Future<AdbResult> disconnect(String target) async {
    return run(['disconnect', target]);
  }

  Future<AdbResult> pair(String ip, int port, String code) async {
    return run(['pair', '$ip:$port', code]);
  }

  Future<AdbResult> reverse(int localPort, int remotePort) async {
    return runOnDevice(['reverse', 'tcp:$localPort', 'tcp:$remotePort']);
  }

  Future<AdbResult> push(String local, String remote) async {
    return runOnDevice(['push', local, remote]);
  }

  Future<AdbResult> shell(String command) async {
    return runOnDevice(['shell', command]);
  }

  Future<AdbResult> installApk(String path) async {
    return runOnDevice(['install', '-r', path]);
  }

  Future<bool> isPackageInstalled(String package) async {
    final result = await shell('pm list packages | grep $package');
    return result.success && result.output.contains(package);
  }

  Future<AdbResult> startService(String package, String service) async {
    return runOnDevice([
      'shell', 'am', 'start-foreground-service',
      '-n', '$package/$service',
    ]);
  }

  Future<AdbResult> launchApp(String package) async {
    return runOnDevice([
      'shell', 'monkey', '-p', package, '-c',
      'android.intent.category.LAUNCHER', '1',
    ]);
  }

  Future<AdbResult> forceStop(String package) async {
    return shell('am force-stop $package');
  }

  Future<AdbResult> killJarProcess() async {
    return shell("ps -A | grep app_process | awk '{print \$2}' | xargs kill");
  }

  void setDevice(AndroidDevice device) {
    _currentDevice = device;
    _deviceId = device.isUsb ? '-d' : device.adbSerial;
  }

  void clearDevice() {
    _currentDevice = null;
    _deviceId = null;
  }
}

extension _ProcessExt on Process {
  int exitTimeOut(Duration timeout) {
    return exitCode;
  }
}
