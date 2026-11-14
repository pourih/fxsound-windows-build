# FxSound Windows Build & Portable Package

Standalone GitHub Actions build pipeline for compiling the `develop/windows` branch of [FxSound](https://github.com/fxsound2/fxsound-app) using JUCE 8 and MSBuild (Visual Studio 2022).

## What This Workflow Does
1. Clones the latest `develop/windows` branch of FxSound.
2. Clones and configures JUCE 8 modules into `C:\JUCE8`.
3. Builds the complete `FxSound.sln` (GUI app, `audiopassthru`, and `DfxDsp`) in Release x64.
4. Packages `FxSound.exe` alongside the factory presets (`Factsoft/`) and Microsoft WHQL-signed audio drivers (`Installer/Drivers/Version14/win10/x64/`).
5. Publishes a ready-to-run portable ZIP bundle (`fxsound-windows-x64-bundle`) with an automated driver registration script (`install_and_run.bat`).

## Running the Output Package Locally
1. Download `fxsound-windows-x64-bundle.zip` from GitHub Actions.
2. Extract to a local folder.
3. Right-click `install_and_run.bat` and select **Run as Administrator** (or run `install_and_run.ps1` in an elevated PowerShell).
4. The script will automatically install the WHQL driver via `fxdevcon64.exe`, configure the audio endpoint registry keys, and launch `FxSound.exe`.
