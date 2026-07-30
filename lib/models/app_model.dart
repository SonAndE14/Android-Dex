class AndroidAppInfo {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final bool isRunning;

  AndroidAppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    this.isRunning = false,
  });

  factory AndroidAppInfo.fromJson(Map<String, dynamic> json) {
    return AndroidAppInfo(
      packageName: json['package'] as String? ?? '',
      appName: json['name'] as String? ?? json['package'] as String? ?? '',
      iconBase64: json['icon'] as String?,
      isRunning: json['running'] as bool? ?? false,
    );
  }
}

class TelemetryData {
  final int batteryLevel;
  final bool isCharging;
  final int volumeLevel;
  final bool isWifiOn;
  final bool isBluetoothOn;
  final String? mediaTitle;
  final String? mediaArtist;
  final bool isMediaPlaying;

  TelemetryData({
    this.batteryLevel = 0,
    this.isCharging = false,
    this.volumeLevel = 50,
    this.isWifiOn = false,
    this.isBluetoothOn = false,
    this.mediaTitle,
    this.mediaArtist,
    this.isMediaPlaying = false,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      batteryLevel: json['battery'] as int? ?? 0,
      isCharging: json['charging'] as bool? ?? false,
      volumeLevel: json['volume'] as int? ?? 50,
      isWifiOn: json['wifi'] as bool? ?? false,
      isBluetoothOn: json['bluetooth'] as bool? ?? false,
      mediaTitle: json['media_title'] as String?,
      mediaArtist: json['media_artist'] as String?,
      isMediaPlaying: json['media_playing'] as bool? ?? false,
    );
  }
}
