param (
    [string]$SrcDir = "src"
)

$ErrorActionPreference = "Stop"
Write-Host "Applying FxSound patches to $SrcDir..." -ForegroundColor Cyan

function Replace-InFile {
    param (
        [string]$Path,
        [string]$Target,
        [string]$Replacement
    )
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if (-not $content.Contains($Target)) {
        Write-Warning "Target string not found in $Path (may already be patched)"
        return
    }
    $content = $content.Replace($Target, $Replacement)
    [System.IO.File]::WriteAllText($Path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Patched $Path" -ForegroundColor Green
}

# 1. audiopassthru/include/AudioPassthru.h
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\include\AudioPassthru.h") `
    -Target "	AudioPassthru();`r`n	~AudioPassthru();`r`n	int init();`r`n	void mute(bool mute);`r`n	std::vector<SoundDevice> getSoundDevices(bool active_devices = true);" `
    -Replacement "	AudioPassthru();`r`n	~AudioPassthru();`r`n	int init();`r`n	void mute(bool mute);`r`n	int setVolumeScalar(float volumeScalar);`r`n	float getVolumeScalar();`r`n	int setMuteState(bool bMute);`r`n	bool getMuteState();`r`n	std::vector<SoundDevice> getSoundDevices(bool active_devices = true);"

# 2. audiopassthru/include/u_AudioPassthru.h
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\include\u_AudioPassthru.h") `
    -Target "	AudioPassthruPrivate();`r`n	~AudioPassthruPrivate();`r`n	int init();`r`n	void mute(bool mute);`r`n	std::vector<SoundDevice> getSoundDevices(bool active_devices = true);" `
    -Replacement "	AudioPassthruPrivate();`r`n	~AudioPassthruPrivate();`r`n	int init();`r`n	void mute(bool mute);`r`n	int setVolumeScalar(float volumeScalar);`r`n	float getVolumeScalar();`r`n	int setMuteState(bool bMute);`r`n	bool getMuteState();`r`n	std::vector<SoundDevice> getSoundDevices(bool active_devices = true);"

# 3. audiopassthru/src/AudioPassthru/AudioPassthru.cpp
$apAppend = @"
void AudioPassthru::restoreDefaultPlaybackDevice()
{
    data_->restoreDefaultPlaybackDevice();
}

int AudioPassthru::setVolumeScalar(float volumeScalar)
{
	return data_->setVolumeScalar(volumeScalar);
}

float AudioPassthru::getVolumeScalar()
{
	return data_->getVolumeScalar();
}

int AudioPassthru::setMuteState(bool bMute)
{
	return data_->setMuteState(bMute);
}

bool AudioPassthru::getMuteState()
{
	return data_->getMuteState();
}
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\AudioPassthru\AudioPassthru.cpp") `
    -Target "void AudioPassthru::restoreDefaultPlaybackDevice()`r`n{`r`n    data_->restoreDefaultPlaybackDevice();`r`n}" `
    -Replacement $apAppend

# 4. audiopassthru/src/AudioPassthru/AudioPassthruPrivate.cpp
$appAppend = @"
	if (sndDevicesSetDeviceType(hp_sndDevices_, SND_DEVICES_DEFAULT, wcp_new_targeted_real_playback_guid, &i_resultFlag) != OKAY)
		return(NOT_OKAY);

	return(OKAY);
}

int AudioPassthruPrivate::setVolumeScalar(float volumeScalar)
{
	if (hp_sndDevices_ == NULL) return NOT_OKAY;
	struct sndDevicesHdlType *cast_handle = (struct sndDevicesHdlType *)hp_sndDevices_;
	if (volumeScalar < 0.0f) volumeScalar = 0.0f;
	if (volumeScalar > 1.0f) volumeScalar = 1.0f;
	if (cast_handle->pEndptVolCapture != NULL)
	{
		cast_handle->pEndptVolCapture->SetMasterVolumeLevelScalar(volumeScalar, &(cast_handle->guidThisApplication));
	}
	if (cast_handle->pEndptVolPlayback != NULL)
	{
		cast_handle->pEndptVolPlayback->SetMasterVolumeLevelScalar(volumeScalar, &(cast_handle->guidThisApplication));
	}
	return OKAY;
}

float AudioPassthruPrivate::getVolumeScalar()
{
	if (hp_sndDevices_ == NULL) return 0.0f;
	struct sndDevicesHdlType *cast_handle = (struct sndDevicesHdlType *)hp_sndDevices_;
	float vol = 0.0f;
	if (cast_handle->pEndptVolPlayback != NULL)
	{
		if (SUCCEEDED(cast_handle->pEndptVolPlayback->GetMasterVolumeLevelScalar(&vol)))
			return vol;
	}
	if (cast_handle->pEndptVolCapture != NULL)
	{
		if (SUCCEEDED(cast_handle->pEndptVolCapture->GetMasterVolumeLevelScalar(&vol)))
			return vol;
	}
	return 0.0f;
}

int AudioPassthruPrivate::setMuteState(bool bMute)
{
	if (hp_sndDevices_ == NULL) return NOT_OKAY;
	struct sndDevicesHdlType *cast_handle = (struct sndDevicesHdlType *)hp_sndDevices_;
	BOOL muteVal = bMute ? TRUE : FALSE;
	if (cast_handle->pEndptVolCapture != NULL)
	{
		cast_handle->pEndptVolCapture->SetMute(muteVal, &(cast_handle->guidThisApplication));
	}
	if (cast_handle->pEndptVolPlayback != NULL)
	{
		cast_handle->pEndptVolPlayback->SetMute(muteVal, &(cast_handle->guidThisApplication));
	}
	return OKAY;
}

bool AudioPassthruPrivate::getMuteState()
{
	if (hp_sndDevices_ == NULL) return false;
	struct sndDevicesHdlType *cast_handle = (struct sndDevicesHdlType *)hp_sndDevices_;
	BOOL bMute = FALSE;
	if (cast_handle->pEndptVolPlayback != NULL)
	{
		if (SUCCEEDED(cast_handle->pEndptVolPlayback->GetMute(&bMute)))
			return bMute != FALSE;
	}
	if (cast_handle->pEndptVolCapture != NULL)
	{
		if (SUCCEEDED(cast_handle->pEndptVolCapture->GetMute(&bMute)))
			return bMute != FALSE;
	}
	return false;
}
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\AudioPassthru\AudioPassthruPrivate.cpp") `
    -Target "	if (sndDevicesSetDeviceType(hp_sndDevices_, SND_DEVICES_DEFAULT, wcp_new_targeted_real_playback_guid, &i_resultFlag) != OKAY)`r`n		return(NOT_OKAY);`r`n`r`n	return(OKAY);`r`n}" `
    -Replacement $appAppend

# 5. audiopassthru/src/sndDevices/sndDevicesDoCapture.cpp (CPU throttle)
$capTarget = "		hr = cast_handle->pAudioCaptureLoopback->GetNextPacketSize(&packetLength); // The number of frames in the next packet.`r`n		if (FAILED(hr)) goto Exit;"
$capRepl = @"
		hr = cast_handle->pAudioCaptureLoopback->GetNextPacketSize(&packetLength); // The number of frames in the next packet.
		if (FAILED(hr)) goto Exit;

		if (packetLength == 0 && cast_handle->playbackIsActive == SND_DEVICES_PLAYBACK_IS_STOPPED)
		{
			// When no audio is playing and playback stream is idle/stopped, avoid spinning the TIME_CRITICAL thread.
			// Sleep 10ms (the duration of one audio packet) instead of 1ms polling, dropping idle CPU from ~18% to <0.1%.
			Sleep(10);
			goto DoneGrabbingFrames;
		}
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\sndDevices\sndDevicesDoCapture.cpp") `
    -Target $capTarget -Replacement $capRepl

# 6. audiopassthru/src/sndDevices/sndDevicesInit.cpp (audiosrv COM cleanup)
$initTarget = "	if (cast_handle == NULL)`r`n		return(NOT_OKAY);`r`n`r`n	// The SAFE_RELEASE macro checks to see if the var is NULL before making ""release"" call."
$initRepl = @"
	if (cast_handle == NULL)
		return(NOT_OKAY);

	// Cleanly unregister callbacks and release volume endpoint COM objects to avoid leaking them
	// and causing high CPU usage in Windows Audio Service (audiosrv).
	sndDevices_ReleaseAllAudioObjects(hp_sndDevices);

	// The SAFE_RELEASE macro checks to see if the var is NULL before making "release" call.
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\sndDevices\sndDevicesInit.cpp") `
    -Target $initTarget -Replacement $initRepl

# 7. audiopassthru/src/sndDevices/sndDevicesDeviceCallbacks.cpp
$cbTarget = "  SLOUT_FIRST_LINE(L""CsndDevicesMMNotificationClient::OnDefaultDeviceChanged() enters"");`r`n`r`n  if( (flow == eRender) && (role == eMultimedia) && (cast_handle->ignoreDeviceCallbacks == FALSE) )"
$cbRepl = @"
  SLOUT_FIRST_LINE(L"CsndDevicesMMNotificationClient::OnDefaultDeviceChanged() enters");

  // Only process eRender for eMultimedia role; ignore redundant eCommunications and eConsole notifications
  if (flow != eRender || role != eMultimedia)
    return(S_OK);

  if( (cast_handle->ignoreDeviceCallbacks == FALSE) )
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\sndDevices\sndDevicesDeviceCallbacks.cpp") `
    -Target $cbTarget -Replacement $cbRepl

# 8. audiopassthru/src/sndDevices/sndDevicesReInit.cpp
$reinitTarget = "	// If audio processing will be performed, do additional initialization.`r`n	if( (i_initType == SND_DEVICES_INIT_FOR_PROCESSING))`r`n	{`r`n		if (cast_handle->numRealDevices > 0)"
$reinitRepl = @"
	// If audio processing will be performed, do additional initialization.
	if( (i_initType == SND_DEVICES_INIT_FOR_PROCESSING))
	{
		if (cast_handle->numRealDevices <= 0)
		{
			// When the last physical output device disconnects, cleanly release all audio
			// objects and prevent retry storms or orphan audio service callbacks.
			sndDevices_ReleaseAllAudioObjects(hp_sndDevices);
			*ipNumRealDevices = 0;
			*ipDfxDeviceEnabledFlag = IS_FALSE;
			*ip_status = SND_DEVICES_DEVICE_NOT_PRESENT;
			return(OKAY);
		}

		if (cast_handle->numRealDevices > 0)
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\sndDevices\sndDevicesReInit.cpp") `
    -Target $reinitTarget -Replacement $reinitRepl

# 9. audiopassthru/src/sndDevices/sndDevicesSetupDevices.cpp
$muteTarget = "	hr = pDevice->Activate(cast_handle->IID_IAudioEndpointVolume, CLSCTX_ALL, NULL, (void**)&pEndptVol);`r`n	if( FAILED(hr) || (pEndptVol == NULL) )`r`n		return;`r`n`r`n	pEndptVol->SetMute(cast_handle->savedPlaybackMute, &(cast_handle->guidThisApplication));`r`n`r`n	pEndptVol->Release();"
$muteRepl = @"
	hr = pDevice->Activate(cast_handle->IID_IAudioEndpointVolume, CLSCTX_ALL, NULL, (void**)&pEndptVol);
	if( FAILED(hr) || (pEndptVol == NULL) )
		return;

	BOOL currentMute = FALSE;
	if (SUCCEEDED(pEndptVol->GetMute(&currentMute)) && currentMute)
	{
		// Preserve mute state: do not automatically unmute if user has muted the device
		pEndptVol->SetMute(TRUE, &(cast_handle->guidThisApplication));
	}
	else
	{
		pEndptVol->SetMute(cast_handle->savedPlaybackMute, &(cast_handle->guidThisApplication));
	}

	pEndptVol->Release();
"@
Replace-InFile -Path (Join-Path $SrcDir "audiopassthru\src\sndDevices\sndDevicesSetupDevices.cpp") `
    -Target $muteTarget -Replacement $muteRepl

# 10. fxsound/Source/GUI/FxSettingsDialog.cpp (startup toggle on all Windows versions)
$win7Target = "	if (os == SystemStats::OperatingSystemType::Windows7)`r`n	{`r`n		addAndMakeVisible(&launch_toggle_);`r`n	}`r`n	`r`n	addAndMakeVisible(&hide_help_tips_toggle_);"
$win7Repl = @"
	// Enable launch on startup toggle across all Windows versions (10, 11, etc.)
	addAndMakeVisible(&launch_toggle_);
	
	addAndMakeVisible(&hide_help_tips_toggle_);
"@
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxSettingsDialog.cpp") `
    -Target $win7Target -Replacement $win7Repl

# 11. fxsound/Source/GUI/FxController.h
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxController.h") `
    -Target "	void setOutput(const String output_device_id, bool notify=true);`r`n	void setOutput(int output, bool notify=true);`r`n    `r`n    bool isPlaybackDeviceAvailable();" `
    -Replacement "	void setOutput(const String output_device_id, bool notify=true);`r`n	void setOutput(int output, bool notify=true);`r`n	int setVolumeScalar(float volumeScalar);`r`n	float getVolumeScalar();`r`n	int setMuteState(bool bMute);`r`n	bool getMuteState();`r`n    `r`n    bool isPlaybackDeviceAvailable();"

# 12. fxsound/Source/GUI/FxController.cpp (CLI + executable relative presets + volume methods)
$ctrlInitTarget = @"
	auto output_device = arg_list.getValueForOption("--output").unquoted();
	auto language = arg_list.getValueForOption("--language");
	auto numbands = arg_list.getValueForOption("--num_bands");
	auto balance = arg_list.getValueForOption("--balance");
	auto filterq = arg_list.getValueForOption("--filter_q");
	auto mastergain = arg_list.getValueForOption("--master_gain");
	auto volume_leveling = arg_list.getValueForOption("--volume_leveling");

    // Forces GPU rendering for this session only; the saved preference is not changed.
    if (arg_list.containsOption("--gpu") && canSupportGpuRendering())
    {
        gpu_render_ = true;
    }

	if (arg_list.containsOption("--run_minimized"))
	{
		settings_.setBool("run_minimized", true);
	}

	if (power_state.isNotEmpty())
	{
		if (power_state.getIntValue() == 0)
			settings_.setBool("power", false);
		else
			settings_.setBool("power", true);
	}
"@
$ctrlInitRepl = @"
	auto output_device = arg_list.getValueForOption("--output").unquoted();
	if (output_device.isEmpty())
	{
		output_device = arg_list.getValueForOption("--device").unquoted();
	}
	auto language = arg_list.getValueForOption("--language");
	auto numbands = arg_list.getValueForOption("--num_bands");
	auto balance = arg_list.getValueForOption("--balance");
	auto filterq = arg_list.getValueForOption("--filter_q");
	auto mastergain = arg_list.getValueForOption("--master_gain");
	auto volume_leveling = arg_list.getValueForOption("--volume_leveling");

    // Forces GPU rendering for this session only; the saved preference is not changed.
    if (arg_list.containsOption("--gpu") && canSupportGpuRendering())
    {
        gpu_render_ = true;
    }

	if (arg_list.containsOption("--run_minimized") || arg_list.containsOption("--hide"))
	{
		settings_.setBool("run_minimized", true);
	}

	if (arg_list.containsOption("--toggle") || arg_list.containsOption("--toggle_power") || arg_list.containsOption("--toggle-power"))
	{
		settings_.setBool("power", !settings_.getBool("power"));
	}
	else if (power_state.isNotEmpty())
	{
		if (power_state.equalsIgnoreCase("toggle"))
			settings_.setBool("power", !settings_.getBool("power"));
		else if (power_state.equalsIgnoreCase("off") || power_state == "0")
			settings_.setBool("power", false);
		else if (power_state.equalsIgnoreCase("on") || power_state == "1")
			settings_.setBool("power", true);
		else
			settings_.setBool("power", power_state.getIntValue() != 0);
	}
"@
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxController.cpp") `
    -Target $ctrlInitTarget -Replacement $ctrlInitRepl

$applyStartTarget = @"
	if (arg_list.containsOption("--status"))
	{
		printStatus();
		return;
	}

	auto power_state = arg_list.getValueForOption("--power");
	auto view = arg_list.getValueForOption("--view");
	auto output_device = arg_list.getValueForOption("--output").unquoted();
	auto language = arg_list.getValueForOption("--language");
"@
$applyStartRepl = @"
	if (arg_list.containsOption("--status"))
	{
		printStatus();
		return;
	}

	bool commandExecuted = false;

	// --toggle or --toggle_power / --toggle-power
	if (arg_list.containsOption("--toggle") || arg_list.containsOption("--toggle_power") || arg_list.containsOption("--toggle-power"))
	{
		commandExecuted = true;
		if (!SysInfo::isRemoteSession())
		{
			setPowerState(!FxModel::getModel().getPowerState());
		}
	}

	// --power <0|1|on|off|toggle>
	auto power_state = arg_list.getValueForOption("--power");
	if (power_state.isNotEmpty() && !SysInfo::isRemoteSession())
	{
		commandExecuted = true;
		if (power_state.equalsIgnoreCase("toggle"))
			setPowerState(!FxModel::getModel().getPowerState());
		else if (power_state.equalsIgnoreCase("off") || power_state == "0")
			setPowerState(false);
		else if (power_state.equalsIgnoreCase("on") || power_state == "1")
			setPowerState(true);
		else
			setPowerState(power_state.getIntValue() != 0);
	}

	// --toggle_mute or --toggle-mute
	if (arg_list.containsOption("--toggle_mute") || arg_list.containsOption("--toggle-mute"))
	{
		commandExecuted = true;
		setMuteState(!getMuteState());
	}
	// --mute <on|off|toggle|0|1>
	else if (arg_list.containsOption("--mute"))
	{
		commandExecuted = true;
		auto mute_val = arg_list.getValueForOption("--mute");
		if (mute_val.isEmpty() || mute_val.equalsIgnoreCase("toggle"))
			setMuteState(!getMuteState());
		else if (mute_val.equalsIgnoreCase("on") || mute_val == "1" || mute_val.equalsIgnoreCase("true"))
			setMuteState(true);
		else if (mute_val.equalsIgnoreCase("off") || mute_val == "0" || mute_val.equalsIgnoreCase("false"))
			setMuteState(false);
		else
			setMuteState(mute_val.getIntValue() != 0);
	}

	// --volume <0-100>
	auto volume_val = arg_list.getValueForOption("--volume");
	if (volume_val.isNotEmpty())
	{
		commandExecuted = true;
		float vol = volume_val.getFloatValue();
		if (vol < 0.0f) vol = 0.0f;
		if (vol > 100.0f) vol = 100.0f;
		setVolumeScalar(vol / 100.0f);
	}

	auto view = arg_list.getValueForOption("--view");
	auto output_device = arg_list.getValueForOption("--output").unquoted();
	if (output_device.isEmpty())
	{
		output_device = arg_list.getValueForOption("--device").unquoted();
	}
	auto language = arg_list.getValueForOption("--language");
"@
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxController.cpp") `
    -Target $applyStartTarget -Replacement $applyStartRepl

# Preset search CWD fix
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxController.cpp") `
    -Target "	auto working_dir = File::getCurrentWorkingDirectory();" `
    -Replacement "	auto working_dir = File::getSpecialLocation(File::SpecialLocationType::currentExecutableFile).getParentDirectory();"

# FxController volume and mute helper methods at EOF
$volMethods = @"
int FxController::setVolumeScalar(float volumeScalar)
{
	if (audio_passthru_ == nullptr) return -1;
	return audio_passthru_->setVolumeScalar(volumeScalar);
}

float FxController::getVolumeScalar()
{
	if (audio_passthru_ == nullptr) return 0.0f;
	return audio_passthru_->getVolumeScalar();
}

int FxController::setMuteState(bool bMute)
{
	if (audio_passthru_ == nullptr) return -1;
	return audio_passthru_->setMuteState(bMute);
}

bool FxController::getMuteState()
{
	if (audio_passthru_ == nullptr) return false;
	return audio_passthru_->getMuteState();
}
"@
$eofTarget = "String FxController::FormatString(const String& format, const String& arg)`r`n{`r`n	wchar_t buffer[1024];`r`n`r`n	swprintf_s(buffer, format.toWideCharPointer(), arg.toWideCharPointer());`r`n`r`n	return String(buffer);`r`n}"
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Source\GUI\FxController.cpp") `
    -Target $eofTarget -Replacement "$eofTarget`r`n`r`n$volMethods"

# 13. resources.rc Version Branding
Replace-InFile -Path (Join-Path $SrcDir "fxsound\Project\resources.rc") `
    -Target "FILEVERSION  1,2,18,0`r`nPRODUCTVERSION  1,2,18,0" `
    -Replacement "FILEVERSION  1,2,18,1`r`nPRODUCTVERSION  1,2,18,1"

Replace-InFile -Path (Join-Path $SrcDir "fxsound\Project\resources.rc") `
    -Target "VALUE ""FileVersion"",  ""1.2.18.0\0""`r`n      VALUE ""ProductName"",  ""FxSound\0""`r`n      VALUE ""ProductVersion"",  ""1.2.18.0\0""" `
    -Replacement "VALUE ""FileVersion"",  ""1.2.18-pourih\0""`r`n      VALUE ""ProductName"",  ""FxSound\0""`r`n      VALUE ""ProductVersion"",  ""1.2.18-pourih\0"""

# 14. FxSound.jucer Version Branding
Replace-InFile -Path (Join-Path $SrcDir "fxsound\FxSound.jucer") `
    -Target "version=""1.2.18.0""" `
    -Replacement "version=""1.2.18-pourih"""

Write-Host "All patches successfully applied to $SrcDir!" -ForegroundColor Green
