import 'package:flutter_test/flutter_test.dart';
import 'package:android_dex/services/adb_service.dart';

void main() {
  group('AdbService', () {
    test('AdbResult constructs correctly', () {
      final result = AdbResult(success: true, output: 'device connected');
      expect(result.success, true);
      expect(result.output, 'device connected');
    });

    test('AndroidDevice parses ADB device line correctly', () {
      final device = AndroidDevice.fromAdbDevicesLine('emulator-5554 device');
      expect(device.id, 'emulator-5554');
      expect(device.isUsb, true);
    });
  });
}
