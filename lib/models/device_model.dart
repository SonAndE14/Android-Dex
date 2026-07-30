class AndroidDevice {
  final String id;
  final String? ipAddress;
  final int? port;
  final bool isUsb;
  final String? model;
  final bool isAuthorized;

  AndroidDevice({
    required this.id,
    this.ipAddress,
    this.port,
    required this.isUsb,
    this.model,
    this.isAuthorized = true,
  });

  bool get isWifi => !isUsb && ipAddress != null;
  String get displayName => model ?? id;
  String get adbSerial => isUsb ? id : '$ipAddress:${port ?? 5555}';

  factory AndroidDevice.fromAdbDevicesLine(String line) {
    final parts = line.split(RegExp(r'\s+'));
    final id = parts.isNotEmpty ? parts[0] : '';
    final isUsb = !id.contains(':');
    return AndroidDevice(id: id, isUsb: isUsb);
  }
}

class ConnectionState {
  final bool jarConnected;
  final bool apkConnected;
  final bool jarReady;
  final bool apkReady;
  final bool isBootComplete;
  final double jarProgress;
  final double apkProgress;
  final double totalProgress;
  final String statusMessage;
  final String? error;
  final bool isError;

  const ConnectionState({
    this.jarConnected = false,
    this.apkConnected = false,
    this.jarReady = false,
    this.apkReady = false,
    this.isBootComplete = false,
    this.jarProgress = 0.0,
    this.apkProgress = 0.0,
    this.totalProgress = 0.0,
    this.statusMessage = 'Initializing...',
    this.error,
    this.isError = false,
  });

  ConnectionState copyWith({
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
  }) {
    return ConnectionState(
      jarConnected: jarConnected ?? this.jarConnected,
      apkConnected: apkConnected ?? this.apkConnected,
      jarReady: jarReady ?? this.jarReady,
      apkReady: apkReady ?? this.apkReady,
      isBootComplete: isBootComplete ?? this.isBootComplete,
      jarProgress: jarProgress ?? this.jarProgress,
      apkProgress: apkProgress ?? this.apkProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      error: error ?? this.error,
      isError: isError ?? this.isError,
    );
  }

  bool get allConnected => jarConnected && apkConnected;
}
