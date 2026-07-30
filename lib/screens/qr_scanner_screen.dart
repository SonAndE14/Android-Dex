import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/adb_service.dart';
import '../services/qr_pairing_service.dart';

class QrScannerScreen extends StatefulWidget {
  final Function(QrPairingResult) onPairingResult;

  const QrScannerScreen({super.key, required this.onPairingResult});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final QrPairingService _qrService = QrPairingService();
  final AdbService _adb = AdbService();
  bool _isProcessing = false;
  String? _statusText;

  void _onQrDetected(String code) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; _statusText = 'Processing QR code...'; });

    final result = _qrService.parseAdbWirelessQr(code);
    if (!mounted) return;

    if (result.success && result.ipAddress != null && result.port != null) {
      setState(() { _statusText = 'Pairing with ${result.ipAddress}:${result.port}...'; });

      String? code = result.errorMessage;
      if (code == null) {
        final match = RegExp(r'(\d{6})').firstMatch(code);
        code = match?.group(1);
      }

      if (code != null) {
        final pairResult = await _adb.pair(result.ipAddress!, result.port!, code);
        if (pairResult.success) {
          setState(() { _statusText = 'Pairing successful! Connecting...'; });
          widget.onPairingResult(result);
          Navigator.of(context).pop();
          return;
        } else {
          setState(() { _statusText = 'Pairing failed: ${pairResult.output}'; });
        }
      } else {
        setState(() { _statusText = 'No pairing code found in QR. Try connecting via IP.'; });
      }
    } else {
      setState(() { _statusText = result.errorMessage ?? 'Invalid QR code'; });
    }

    setState(() { _isProcessing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan the QR code from your phone',
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Settings → Developer Options → Wireless Debugging\n→ Pair device with QR code',
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.primaryColor, width: 2),
                color: Colors.white.withOpacity(0.05),
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner, size: 80, color: AppConstants.primaryColor),
                          const SizedBox(height: 16),
                          const Text(
                            'Camera preview would appear here',
                            style: TextStyle(color: AppConstants.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '(mobile_scanner package)',
                            style: TextStyle(color: AppConstants.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            if (_statusText != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13),
                ),
              ),

            const SizedBox(height: 24),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  _statusText = null;
                  _isProcessing = false;
                });
              },
              icon: const Icon(Icons.refresh, color: AppConstants.primaryColor),
              label: const Text('Reset Scanner', style: TextStyle(color: AppConstants.primaryColor)),
            ),

            const SizedBox(height: 32),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppConstants.warningColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On your Android 11+ device, enable Wireless Debugging, '
                      'then tap "Pair device with QR code"',
                      style: TextStyle(color: AppConstants.warningColor.withOpacity(0.9), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MockQrInputScreen extends StatelessWidget {
  final Function(QrPairingResult) onPairingResult;

  const MockQrInputScreen({super.key, required this.onPairingResult});

  @override
  Widget build(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    final QrPairingService qrService = QrPairingService();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(title: const Text('Enter QR Code Manually')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              maxLines: 4,
              style: const TextStyle(color: AppConstants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Paste QR code content here...',
                filled: true,
                fillColor: AppConstants.cardColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final result = qrService.parseAdbWirelessQr(codeController.text);
                onPairingResult(result);
                if (result.success) {
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.errorMessage ?? 'Parse failed')),
                  );
                }
              },
              child: const Text('Parse & Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
