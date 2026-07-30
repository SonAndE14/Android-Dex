import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/app_model.dart';
import '../providers/app_state.dart';
import '../providers/connection_state.dart';
import '../services/adb_service.dart';
import '../services/scrcpy_service.dart';
import 'device_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdbService _adb = AdbService();
  final ScrcpyService _scrcpy = ScrcpyService();
  final TextEditingController _searchController = TextEditingController();
  List<AndroidAppInfo> _filteredApps = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final appState = context.read<AppStateProvider>();
    appState.setScanningApps(true);

    final result = await _adb.shell('cmd package list packages -3');
    if (result.success && mounted) {
      final packages = result.output
          .split('\n')
          .where((line) => line.startsWith('package:'))
          .map((line) => line.replaceFirst('package:', '').trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final apps = packages.map((p) => AndroidAppInfo(
        packageName: p,
        appName: p.split('.').last,
      )).toList();

      appState.setInstalledApps(apps);
      setState(() { _filteredApps = apps; });
    }
    appState.setScanningApps(false);
  }

  void _searchApps(String query) {
    final appState = context.read<AppStateProvider>();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = appState.installedApps;
      } else {
        _filteredApps = appState.installedApps
            .where((app) =>
                app.appName.toLowerCase().contains(query.toLowerCase()) ||
                app.packageName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _launchApp(String packageName) async {
    final device = _adb.currentDevice;
    if (device == null) return;

    setState(() {});
    await _scrcpy.launchAppWindow(packageName, _adb.adbArgs);
    await _adb.launchApp(packageName);
  }

  Future<void> _stopApp(String packageName) async {
    await _adb.forceStop(packageName);
    await _scrcpy.closeWindow(packageName);
  }

  void _disconnect() {
    context.read<ConnectionStateProvider>().reset();
    _scrcpy.closeAll();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DeviceManagerScreen(
        onDeviceSelected: null,
      )),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final connectionState = context.watch<ConnectionStateProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppConstants.surfaceColor,
              border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 1)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/app_png.png',
                  width: 28, height: 28,
                  errorBuilder: (_, __, ___) => const Icon(Icons.phone_android, color: AppConstants.primaryColor, size: 28),
                ),
                const SizedBox(width: 10),
                const Text('Android DEX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                const Spacer(),
                // Device info
                if (_adb.currentDevice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.successColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppConstants.successColor)),
                        const SizedBox(width: 6),
                        Text(
                          _adb.currentDevice!.isUsb ? 'USB' : 'Wi-Fi',
                          style: const TextStyle(color: AppConstants.successColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                // Battery
                if (appState.telemetry.batteryLevel > 0)
                  Row(
                    children: [
                      Icon(Icons.battery_std, color: appState.telemetry.batteryLevel > 20 ? AppConstants.textSecondary : AppConstants.warningColor, size: 18),
                      const SizedBox(width: 4),
                      Text('${appState.telemetry.batteryLevel}%', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                const SizedBox(width: 12),
                // Volume
                if (appState.telemetry.volumeLevel > 0)
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: AppConstants.textSecondary, size: 18),
                      const SizedBox(width: 4),
                      Text('${appState.telemetry.volumeLevel}%', style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                const SizedBox(width: 16),
                // Actions
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConstants.textSecondary, size: 20),
                  onPressed: _loadApps,
                  tooltip: 'Refresh apps',
                ),
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: AppConstants.errorColor, size: 20),
                  onPressed: _disconnect,
                  tooltip: 'Disconnect',
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchApps,
              style: const TextStyle(color: AppConstants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search, color: AppConstants.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppConstants.textSecondary),
                        onPressed: () { _searchController.clear(); _searchApps(''); },
                      )
                    : null,
                filled: true,
                fillColor: AppConstants.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // App grid
          Expanded(
            child: appState.isScanningApps
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _filteredApps.isEmpty
                    ? const Center(child: Text('No apps found', style: TextStyle(color: AppConstants.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return _AppCard(
                            app: app,
                            onLaunch: () => _launchApp(app.packageName),
                            onStop: app.isRunning ? () => _stopApp(app.packageName) : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final AndroidAppInfo app;
  final VoidCallback onLaunch;
  final VoidCallback? onStop;

  const _AppCard({
    required this.app,
    required this.onLaunch,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onLaunch,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: app.isRunning
              ? Border.all(color: AppConstants.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.android, color: AppConstants.textSecondary, size: 28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                app.appName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 12),
              ),
            ),
            if (app.isRunning)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('RUNNING', style: TextStyle(color: AppConstants.successColor, fontSize: 8)),
              ),
          ],
        ),
      ),
    );
  }
}
