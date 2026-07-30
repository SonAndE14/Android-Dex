import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';

class ScrcpyInstance {
  final String packageName;
  final int scrcpyPid;
  final int windowId;
  bool isRunning;

  ScrcpyInstance({
    required this.packageName,
    required this.scrcpyPid,
    required this.windowId,
    this.isRunning = true,
  });
}

class ScrcpyService {
  static final ScrcpyService _instance = ScrcpyService._();
  factory ScrcpyService() => _instance;
  ScrcpyService._();

  String? _scrcpyPath;
  final List<ScrcpyInstance> _instances = [];
  final Set<int> _usedPorts = {};

  int get nextPort {
    for (int i = 27183; i < 27200; i++) {
      if (!_usedPorts.contains(i)) {
        _usedPorts.add(i);
        return i;
      }
    }
    return 27183;
  }

  Future<bool> initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _scrcpyPath = '${dir.path}\\${AppConstants.scrcpyExecutable}';
      if (!File(_scrcpyPath!).existsSync()) {
        _scrcpyPath = 'scrcpy.exe';
      }
      return true;
    } catch (e) {
      _scrcpyPath = 'scrcpy.exe';
      return true;
    }
  }

  Future<ScrcpyInstance?> launchAppWindow(String packageName, String deviceArg) async {
    try {
      final port = nextPort;
      final process = await Process.start(
        _scrcpyPath ?? 'scrcpy.exe',
        [
          ...deviceArg.split(' '),
          '--window-title', packageName,
          '--max-size', '1920',
          '--bit-rate', '8M',
          '--lock-video-orientation', '0',
          '--no-audio',
          '--port', '$port',
          '--push-target', '/data/local/tmp/scrcpy-server.jar',
        ],
        runInShell: true,
        mode: ProcessStartMode.detachedWithStdout,
      );

      final instance = ScrcpyInstance(
        packageName: packageName,
        scrcpyPid: process.pid,
        windowId: port,
      );
      _instances.add(instance);

      process.exitCode.then((_) {
        instance.isRunning = false;
        _usedPorts.remove(port);
      });

      return instance;
    } catch (e) {
      debugPrint('Failed to launch scrcpy for $packageName: $e');
      return null;
    }
  }

  Future<void> closeWindow(String packageName) async {
    final instance = _instances.where((i) => i.packageName == packageName).toList();
    for (final inst in instance) {
      try {
        Process.killPid(inst.scrcpyPid);
      } catch (_) {}
      inst.isRunning = false;
      _instances.remove(inst);
    }
  }

  Future<void> closeAll() async {
    for (final inst in _instances.toList()) {
      try {
        Process.killPid(inst.scrcpyPid);
      } catch (_) {}
      inst.isRunning = false;
    }
    _instances.clear();
    _usedPorts.clear();
  }

  List<ScrcpyInstance> get runningInstances =>
      _instances.where((i) => i.isRunning).toList();
}
