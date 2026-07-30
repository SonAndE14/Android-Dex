import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/device_model.dart';
import '../services/adb_service.dart';
import 'qr_scanner_screen.dart';

class DeviceManagerScreen extends StatefulWidget {
  final Function(AndroidDevice)? onDeviceSelected;

  const DeviceManagerScreen({super.key, this.onDeviceSelected});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  final AdbService _adb = AdbService();
  final TextEditingController _ipController = TextEditingController();
  List<AndroidDevice> _devices = [];
  bool _scanning = false;
  String? _ipError;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() { _scanning = true; });
    final devices = await _adb.getDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _scanning = false;
      });
    }
  }

  Future<void> _connectByIp() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _ipError = 'Please enter an IP address');
      return;
    }

    setState(() { _connecting = true; _ipError = null; });

    final result = await _adb.connect(ip);
    if (!mounted) return;

    if (result.success && (result.output.contains('connected') || result.output.contains('already'))) {
      final device = AndroidDevice(
        id: '$ip:5555',
        ipAddress: ip,
        port: 5555,
        isUsb: false,
      );
      _selectDevice(device);
    } else {
      setState(() {
        _ipError = 'Unable to connect to $ip:5555. Verify the IP and try again.';
        _connecting = false;
      });
    }
  }

  void _selectDevice(AndroidDevice device) {
    _adb.setDevice(device);
    if (widget.onDeviceSelected != null) {
      widget.onDeviceSelected!(device);
      Navigator.of(context).pop();
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onPairingResult: (result) {
            if (result.ipAddress != null) {
              _ipController.text = result.ipAddress!;
              _connectByIp();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('ADB Device Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openQrScanner,
            icon: const Icon(Icons.qr_code_scanner, color: AppConstants.primaryColor),
            label: const Text('QR Pair', style: TextStyle(color: AppConstants.primaryColor)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Device list
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                      TextButton.icon(
                        onPressed: _scanDevices,
                        icon: Icon(Icons.refresh, size: 18, color: _scanning ? AppConstants.textSecondary : AppConstants.primaryColor),
                        label: Text(_scanning ? 'Scanning...' : 'Refresh', style: TextStyle(color: _scanning ? AppConstants.textSecondary : AppConstants.primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _scanning
                        ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                        : _devices.isEmpty
                            ? const Center(child: Text('No ADB devices found', style: TextStyle(color: AppConstants.textSecondary)))
                            : ListView.builder(
                                itemCount: _devices.length,
                                itemBuilder: (context, index) {
                                  final device = _devices[index];
                                  return _DeviceRow(
                                    device: device,
                                    onTap: () => _selectDevice(device),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // IP connection panel
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Connect via IP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(color: AppConstants.textPrimary),
                      decoration: InputDecoration(
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.language, color: AppConstants.textSecondary),
                        errorText: _ipError,
                        filled: true,
                        fillColor: AppConstants.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _connectByIp(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Port: 5555 (auto-appended)', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _connecting ? null : _connectByIp,
                        icon: _connecting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.link),
                        label: Text(_connecting ? 'Connecting...' : 'Connect'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF333333)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openQrScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF2D2D2D),
                        side: const BorderSide(color: AppConstants.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use the QR code from:\nSettings → Developer Options → Wireless Debugging → Pair device with QR code',
                      style: TextStyle(color: AppConstants.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final AndroidDevice device;
  final VoidCallback onTap;

  const _DeviceRow({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isUsb
              ? Colors.blue.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            device.isUsb ? Icons.usb : Icons.wifi,
            color: device.isUsb ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          device.displayName,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        subtitle: Text(
          device.isUsb ? 'USB Device - ${device.id}' : 'Wi-Fi ADB - ${device.adbSerial}',
          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppConstants.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
