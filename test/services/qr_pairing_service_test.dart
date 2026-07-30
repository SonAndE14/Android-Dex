import 'package:flutter_test/flutter_test.dart';
import 'package:android_dex/services/qr_pairing_service.dart';

void main() {
  group('QrPairingService', () {
    late QrPairingService service;

    setUp(() {
      service = QrPairingService();
    });

    test('parses ADB wireless debugging QR with code', () {
      final result = service.parseAdbWirelessQr('192.168.1.100:41315#123456');
      expect(result.success, true);
      expect(result.ipAddress, '192.168.1.100');
      expect(result.port, 41315);
    });

    test('fails on non-ADB QR codes', () {
      final result = service.parseAdbWirelessQr('WIFI:T:WPA;S:MyWiFi;P:password;;');
      expect(result.success, false);
    });

    test('extracts pairing code from QR', () {
      final result = service.parseAdbWirelessQr('192.168.1.100:41315#987654');
      expect(result.success, true);
      expect(result.errorMessage, '987654');
    });
  });
}
