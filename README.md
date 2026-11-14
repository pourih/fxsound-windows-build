# FxSound Enhanced (v1.2.18-pourih)

An enhanced, standalone distribution of [FxSound](https://github.com/fxsound2/fxsound-app) for Windows. It integrates critical performance optimizations, resource leak fixes, full headless command-line automation, and Microsoft WHQL-signed virtual audio drivers into an all-in-one setup package.

---

## ⬇️ Download & Installation

### [👉 Click Here to Download the Installer (`fxsound_setup_1.2.18-pourih.exe`)](https://github.com/pourih/fxsound-windows-build/releases/latest)

1. Download **`fxsound_setup_1.2.18-pourih.exe`** from the link above (or from the [Releases](https://github.com/pourih/fxsound-windows-build/releases) tab).
2. Run the installer (Administrator privileges are required for driver registration).
3. In the setup wizard, ensure the **"Install FxSound virtual audio driver"** option is checked (required if you don't already have the FxSound driver installed).
4. Click **Install**. The setup will register the WHQL driver, configure the audio device endpoints, and launch FxSound.

---

## What's Enhanced in v1.2.18-pourih

### 1. Performance & System Reliability
* **Idle Audio Loopback Throttle (<0.1% CPU)**: Added backoff polling when WASAPI reports silence, eliminating the ~18% CPU spin on silent audio threads ([#671](https://github.com/fxsound2/fxsound-app/issues/671)).
* **Audio Service Leak Prevention**: Explicitly unregisters COM notification sinks and releases endpoint objects on device disconnect, preventing memory leaks and CPU spikes in Windows Audio Service `audiosrv.dll` ([#580](https://github.com/fxsound2/fxsound-app/issues/580)).
* **Volume Burst Fix**: Synchronizes virtual endpoint volume to physical device levels rather than blasting 100% volume on device switch ([#607](https://github.com/fxsound2/fxsound-app/issues/607), [#615](https://github.com/fxsound2/fxsound-app/issues/615)).
* **Startup Preset Resolution**: Resolves factory presets (`Factsoft/`) relative to the executable path so presets never vanish when launching with Windows on boot ([#107](https://github.com/fxsound2/fxsound-app/issues/107)).
* **Startup Toggle for Windows 10/11**: Removes legacy Windows 7 check so the launch-on-boot setting is accessible across all modern Windows versions ([#18](https://github.com/fxsound2/fxsound-app/issues/18), [#664](https://github.com/fxsound2/fxsound-app/issues/664)).
* **Crash Auto-Relaunch**: Automatic process recovery on unexpected device faults.

### 2. Audio Engine & UI Features
* **Modern JUCE 8 / C++20 Framework**: Compiled with Visual Studio 2022 toolset for optimal stability and audio throughput.
* **Undo Preset Button**: Revert EQ adjustments back to the saved preset state directly from the dropdown.
* **GPU-Accelerated Rendering Toggle**: Native toggle in Settings to switch between software rendering and OpenGL GPU rendering.
* **Double-Click Reset**: Double-click any EQ slider or frequency knob to snap back to default.

### 3. Microsoft WHQL-Signed Audio Driver
* Bundled with Microsoft Windows Hardware Compatibility Publisher signed virtual audio driver (`fxvad.sys` / `fxvadntamd64.cat`).
* The installer presents an optional checkbox allowing you to choose whether to install/register the driver.

---

## Headless Command-Line Interface (CLI)

Control FxSound silently from hotkeys, scripts, Task Scheduler, or Stream Deck without the GUI window popping up over your active games or applications:

```powershell
# Power toggle
FxSound.exe --toggle
FxSound.exe --power on    # or: --power off

# Mute toggle
FxSound.exe --toggle-mute
FxSound.exe --mute on     # or: --mute off

# Master volume (0 - 100)
FxSound.exe --volume 75

# Preset switch (case-insensitive / partial match)
FxSound.exe --preset "Gaming"
FxSound.exe --preset "Music"

# Output device switch (case-insensitive / partial match)
FxSound.exe --device "Headphones"
FxSound.exe --output "Realtek"

# Status dump (JSON to %AppData%\Roaming\FxSound\status.json)
FxSound.exe --status
```

---

## Building From Source

This project includes a continuous integration workflow that builds the application and installer via GitHub Actions.

* **Workflow File**: [`.github/workflows/build-windows.yml`](.github/workflows/build-windows.yml)
* **Compiler**: Visual Studio 2022 MSBuild (`v143`), JUCE 8, Inno Setup 6.

---

## License

[AGPLv3](./LICENSE) (inherited from upstream).
