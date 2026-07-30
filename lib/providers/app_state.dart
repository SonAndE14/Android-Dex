import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/app_model.dart';
import '../models/device_model.dart';

class AppStateProvider extends ChangeNotifier {
  final List<AndroidAppInfo> _installedApps = [];
  TelemetryData _telemetry = TelemetryData();
  AndroidDevice? _selectedDevice;
  bool _isScanningApps = false;
  String? _lastError;

  UnmodifiableListView<AndroidAppInfo> get installedApps =>
      UnmodifiableListView(_installedApps);
  TelemetryData get telemetry => _telemetry;
  AndroidDevice? get selectedDevice => _selectedDevice;
  bool get isScanningApps => _isScanningApps;
  String? get lastError => _lastError;

  void setInstalledApps(List<AndroidAppInfo> apps) {
    _installedApps.clear();
    _installedApps.addAll(apps);
    notifyListeners();
  }

  void updateTelemetry(TelemetryData data) {
    _telemetry = data;
    notifyListeners();
  }

  void setSelectedDevice(AndroidDevice? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  void setScanningApps(bool scanning) {
    _isScanningApps = scanning;
    notifyListeners();
  }

  void setError(String? error) {
    _lastError = error;
    notifyListeners();
  }
}
