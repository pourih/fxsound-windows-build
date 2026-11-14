# FxSound Standalone (v1.2.18-pourih)

Combined standalone distribution of [FxSound](https://github.com/fxsound2/fxsound-app) merging the latest `develop/windows` branch with essential stability, efficiency, and headless CLI enhancements.

## What's in this Release (v1.2.18-pourih)

### 1. Features from Upstream `develop/windows`
* **JUCE 8 / C++20 Framework**: Built against the latest audio engine framework with VS 2022 toolset.
* **Undo Preset Button**: Easily revert EQ adjustments back to the saved state from the preset dropdown.
* **GPU Rendering Toggle**: Native switch in Settings to enable OpenGL GPU-accelerated UI rendering.
* **Crash Auto-Relaunch**: Graceful background recovery if an audio device error occurs.
* **Double-Click Reset**: Double-click any EQ slider or knob to snap back to default.

### 2. Patches from `pourih/fxsound-win-private`
* **Idle CPU Throttle (<0.1% CPU)**: Added backoff polling when WASAPI reports silence, eliminating the 18% CPU spin on silent audio threads ([#671](https://github.com/fxsound2/fxsound-app/issues/671)).
* **Audio Service Leak Prevention**: Explicitly unregisters COM notification sinks and releases endpoint objects on device disconnect, preventing memory leaks in `audiosrv.dll` ([#580](https://github.com/fxsound2/fxsound-app/issues/580)).
* **Volume Burst Fix**: Synchronizes virtual endpoint volume to physical device levels rather than blasting 100% volume on device switch ([#607](https://github.com/fxsound2/fxsound-app/issues/607), [#615](https://github.com/fxsound2/fxsound-app/issues/615)).
* **Headless CLI Controls**: Control power, mute, volume, presets, and devices silently from scripts, shortcuts, or Stream Deck without stealing window focus ([#27](https://github.com/fxsound2/fxsound-app/issues/27)).
* **Startup Preset Fix**: Resolves factory presets (`Factsoft/`) relative to the executable path so presets never vanish when starting with Windows ([#107](https://github.com/fxsound2/fxsound-app/issues/107)).
* **Startup Toggle for Windows 10/11**: Removes legacy Windows 7 check so the launch-on-boot setting is available everywhere ([#18](https://github.com/fxsound2/fxsound-app/issues/18), [#664](https://github.com/fxsound2/fxsound-app/issues/664)).

### 3. Microsoft WHQL-Signed Driver Pairing
* Bundled with Microsoft Windows Hardware Compatibility Publisher signed virtual audio driver (`fxvad.sys` / `fxvadntamd64.cat`).
* Inno Setup installer includes an explicit prompt/checkbox to install the driver during setup.

---

## Headless CLI Automation

```powershell
# Power toggle
FxSound.exe --toggle
FxSound.exe --power on    # or: --power off

# Mute toggle
FxSound.exe --toggle-mute
FxSound.exe --mute on     # or: --mute off

# Volume (0 - 100)
FxSound.exe --volume 75

# Preset switch (case-insensitive / partial match)
FxSound.exe --preset "Gaming"
FxSound.exe --preset "Music"

# Output device switch (case-insensitive / partial match)
FxSound.exe --device "Headphones"
FxSound.exe --output "Realtek"

# Status dump
FxSound.exe --status
```
