import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/device_model.dart';
import '../providers/connection_state.dart';
import '../services/adb_service.dart';
import 'device_manager_screen.dart';
import 'home_screen.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with TickerProviderStateMixin {
  final AdbService _adb = AdbService();
  bool _initializing = false;
  String _statusText = 'Initializing Android DEX...';
  double _overallProgress = 0.0;
  double _jarProgress = 0.0;
  double _apkProgress = 0.0;
  bool _showDevicePicker = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(_pulseController);
    _autoDetect();
  }

  Future<void> _autoDetect() async {
    setState(() { _initializing = true; _statusText = 'Scanning for ADB devices...'; });

    final devices = await _adb.getDevices();
    if (!mounted) return;

    if (devices.isEmpty) {
      setState(() {
        _showDevicePicker = true;
        _initializing = false;
        _statusText = 'No devices found. Select a device or connect via IP.';
      });
    } else if (devices.length == 1) {
      _startConnection(devices.first);
    } else {
      setState(() {
        _showDevicePicker = true;
        _initializing = false;
        _statusText = 'Multiple devices found. Please select one.';
      });
    }
  }

  Future<void> _startConnection(AndroidDevice device) async {
    setState(() { _initializing = true; _errorMessage = null; });

    final connection = context.read<ConnectionStateProvider>();
    connection.addListener(_onConnectionUpdate);
    await connection.startConnection(device);
  }

  void _onConnectionUpdate() {
    if (!mounted) return;
    final connection = context.read<ConnectionStateProvider>();
    final state = connection.state;

    setState(() {
      _jarProgress = state.jarProgress;
      _apkProgress = state.apkProgress;
      _overallProgress = state.totalProgress;
      _statusText = state.statusMessage;
      _initializing = !state.isBootComplete && !state.isError;

      if (state.isError) {
        _errorMessage = state.error;
        _showDevicePicker = true;
      }
    });

    if (state.isBootComplete) {
      connection.removeListener(_onConnectionUpdate);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }
  }

  void _onDeviceSelected(AndroidDevice device) {
    setState(() { _showDevicePicker = false; _errorMessage = null; });
    _startConnection(device);
  }

  void _openDeviceManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceManagerScreen(
          onDeviceSelected: _onDeviceSelected,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/app_png.png',
                width: 96,
                height: 96,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.phone_android,
                  size: 96,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Android DEX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.appVersion,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Progress bars
              SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar('JAR Engine', _jarProgress, AppConstants.primaryColor),
                    const SizedBox(height: 12),
                    _buildProgressBar('App Hub', _apkProgress, AppConstants.accentColor),
                    const SizedBox(height: 12),
                    _buildProgressBar('System', _overallProgress, AppConstants.successColor),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConstants.errorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConstants.errorColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppConstants.errorColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Device picker button
              if ((_showDevicePicker || _errorMessage != null) && !_initializing)
                ElevatedButton.icon(
                  onPressed: _openDeviceManager,
                  icon: const Icon(Icons.devices),
                  label: const Text('Open ADB Manager'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    backgroundColor: AppConstants.primaryColor,
                  ),
                ),

              // Loading indicator
              if (_initializing)
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
