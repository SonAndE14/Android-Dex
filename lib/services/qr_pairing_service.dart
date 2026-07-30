import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class QrPairingResult {
  final bool success;
  final String? ipAddress;
  final int? port;
  final String? code;
  final String? errorMessage;

  QrPairingResult({
    required this.success,
    this.ipAddress,
    this.port,
    this.code,
    this.errorMessage,
  });
}

class QrPairingService {
  static final QrPairingService _instance = QrPairingService._();
  factory QrPairingService() => _instance;
  QrPairingService._();

  QrPairingResult parseQrCode(String qrContent) {
    try {
      if (qrContent.startsWith('WIFI:')) {
        return _parseWifiQr(qrContent);
      }
      if (qrContent.contains(':') && qrContent.contains('#')) {
        return _parseAdbPairingCode(qrContent);
      }
      return QrPairingResult(
        success: false,
        errorMessage: 'QR code format not recognized. Use Android Wireless Debugging QR.',
      );
    } catch (e) {
      return QrPairingResult(
        success: false,
        errorMessage: 'Failed to parse QR code: $e',
      );
    }
  }

  QrPairingResult _parseWifiQr(String content) {
    try {
      final params = <String, String>{};
      for (final part in content.substring(5).split(';')) {
        final eq = part.indexOf(':');
        if (eq > 0) {
          params[part.substring(0, eq)] = part.substring(eq + 1);
        }
      }
      return QrPairingResult(
        success: false,
        errorMessage: 'This is a Wi-Fi network QR code. '
            'Please use the Wireless Debugging QR from Developer Options.',
      );
    } catch (e) {
      return QrPairingResult(success: false, errorMessage: e.toString());
    }
  }

  QrPairingResult _parseAdbPairingCode(String content) {
    try {
      final cleanContent = content.trim();
      final parts = cleanContent.split(RegExp(r'[: #\n]'));

      if (parts.length >= 3) {
        String? ip;
        int? port;
        String? code;

        for (int i = 0; i < parts.length - 2; i++) {
          final first = parts[i].trim();
          final second = parts[i + 1].trim();
          final third = parts[i + 2].trim();

          if (_isIpAddress(first) && second.contains(RegExp(r'^\d+$'))) {
            ip = first;
            port = int.tryParse(second);
            if (i + 3 < parts.length) {
              code = parts[i + 3].trim();
            }
            break;
          }
        }

        if (ip != null && port != null && code != null) {
          return QrPairingResult(
            success: true,
            ipAddress: ip,
            port: port,
            code: code,
          );
        }
      }

      return QrPairingResult(
        success: false,
        errorMessage: 'Could not parse ADB pairing info from QR. '
            'Expected format: IP:PORT#CODE',
      );
    } catch (e) {
      return QrPairingResult(success: false, errorMessage: e.toString());
    }
  }

  QrPairingResult parseAdbWirelessQr(String rawData) {
    try {
      final cleaned = rawData.replaceAll(RegExp(r'[\s"]'), '');
      if (cleaned.contains('WIFI')) {
        return _parseWifiQr(cleaned);
      }
      final colonCount = ':'.allMatches(cleaned).length;
      if (colonCount >= 2) {
        final match = RegExp(r'(\d+\.\d+\.\d+\.\d+):(\d+)(?:[#:])?(\d{6})?').firstMatch(cleaned);
        if (match != null) {
          final ip = match.group(1)!;
          final port = int.parse(match.group(2)!);
          final code = match.group(3);
          return QrPairingResult(
            success: true,
            ipAddress: ip,
            port: port,
            code: code,
          );
        }
      }
      final simpleMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+):(\d+)').firstMatch(cleaned);
      if (simpleMatch != null) {
        return QrPairingResult(
          success: true,
          ipAddress: simpleMatch.group(1),
          port: int.parse(simpleMatch.group(2)!),
          errorMessage: 'No pairing code found in QR',
        );
      }
      return QrPairingResult(success: false, errorMessage: 'Could not parse ADB QR code');
    } catch (e) {
      return QrPairingResult(success: false, errorMessage: e.toString());
    }
  }

  bool _isIpAddress(String s) {
    final parts = s.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) => int.tryParse(p) != null && int.parse(p) >= 0 && int.parse(p) <= 255);
  }
}
