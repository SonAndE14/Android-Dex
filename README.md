# Android DEX

Transform your Android device into a desktop experience. Mirror apps, control your phone, stream audio, manage media, launch multiple Android apps, and connect over USB or Wi-Fi — all from Windows.

## Quick Download

| Platform | Download Link |
|----------|--------------|
| **Windows Installer** | [android_dex_setup_0.9.0.exe](https://github.com/Shrey113/Android-Dex/releases/latest) |
| **Windows Portable** | [android_dex_win.zip](https://github.com/Shrey113/Android-Dex/releases/latest/download/android_dex_win.zip) |

## Features

- **Multi-Window Apps** — Each Android app runs in its own resizable Windows window
- **Wireless ADB** — Connect via Wi-Fi with QR code pairing (Android 11+)
- **USB Connection** — Plug & play with automatic detection
- **Live Telemetry** — Real-time battery, volume, Wi-Fi, Bluetooth status
- **Notifications** — Android notifications pushed to Windows desktop
- **Media Control** — Artwork, metadata and playback controls
- **Low Latency** — scrcpy-powered screen mirroring with minimal lag
- **Auto-Healing** — Multi-stage recovery restores connection seamlessly

## Getting Started

### Prerequisites
- **OS**: Windows 10+ (64-bit)
- **Device**: Android 8.0+ (Android 11+ for wireless QR pairing)
- **Drivers**: ADB is bundled — no separate installation needed

### Step-by-Step
1. **Enable Developer Options** on your phone: Settings → About Phone → tap Build Number 7 times
2. **Enable USB Debugging**: Settings → Developer Options → USB Debugging → ON
3. **For Wireless**: Enable Wireless Debugging → tap "Pair device with QR code"
4. **Launch Android DEX** — watch the boot progress bars fill to 100%
5. **The desktop unlocks** — your Android is now a full Windows desktop experience

### Launch Options
| Command | Description |
|---------|-------------|
| `android_dex_win.exe` | Auto-detect — recommended for most users |
| `android_dex_win.exe --usb` | Force USB connection only |
| `android_dex_win.exe 192.168.1.100` | Connect via IP address |
| `android_dex_win.exe --qr` | Open QR scanner on launch |

## Architecture

```
Windows Side (Flutter/ADB)
    │
    ├── TCP ──► Android Logic Engine (Java JAR)
    │              - Volume control, app launch, system commands
    │
    └── WebSocket ──► Android Feature Hub (Kotlin APK)
                       - Notifications, media, telemetry
```

## Building from Source

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. Clone this repository
3. Run:
```bash
flutter pub get
flutter build windows --release
```
4. The executable will be in `build\windows\x64\runner\Release\`

## License

Apache 2.0
