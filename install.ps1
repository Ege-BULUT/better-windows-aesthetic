# Installs one component of Better Windows Aesthetic. Called by setup.iss once per selected component.
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 -Step <name>
param(
    [Parameter(Mandatory)]
    [ValidateSet('theme', 'translucenttb', 'lively-install', 'lively-config', 'zen-install', 'zen-config', 'widgets', 'flow')]
    [string]$Step
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Assets = Join-Path $PSScriptRoot 'assets'
$Downloads = Join-Path $env:TEMP 'better-windows-aesthetic'
New-Item -ItemType Directory -Force $Downloads | Out-Null
Start-Transcript -Append -Path (Join-Path $env:TEMP 'better-windows-aesthetic.log') | Out-Null

function Get-File($url, $name) {
    $path = Join-Path $Downloads $name
    Write-Host "Downloading $url" # not Write-Output: that would become part of the return value
    Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
    $path
}

function Get-GitHubAsset($repo, $pattern) {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing
    $asset = $release.assets | Where-Object name -match $pattern | Select-Object -First 1
    if (-not $asset) { throw "No asset matching '$pattern' in $repo $($release.tag_name)" }
    Get-File $asset.browser_download_url $asset.name
}

function Set-Autostart($name, $command) {
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $name -Value $command
}

function Wait-Until($seconds, [scriptblock]$condition) {
    for ($i = 0; $i -lt $seconds; $i++) {
        if (& $condition) { return $true }
        Start-Sleep -Seconds 1
    }
    $false
}

switch ($Step) {
    'theme' {
        # Dark mode + transparency effects: the Start menu, taskbar flyouts and Settings become translucent acrylic
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Set-ItemProperty -Path $key -Name EnableTransparency -Value 1 -Type DWord
        Set-ItemProperty -Path $key -Name AppsUseLightTheme -Value 0 -Type DWord
        Set-ItemProperty -Path $key -Name SystemUsesLightTheme -Value 0 -Type DWord
    }

    'translucenttb' {
        $dir = Join-Path $env:LOCALAPPDATA 'Programs\TranslucentTB'
        Get-Process TranslucentTB -ErrorAction SilentlyContinue | Stop-Process -Force
        Expand-Archive -Path (Get-GitHubAsset 'TranslucentTB/TranslucentTB' '^TranslucentTB-portable-x64\.zip$') -DestinationPath $dir -Force
        # The portable build reads settings.json next to its exe
        Copy-Item (Join-Path $Assets 'translucenttb\settings.json') $dir -Force
        $exe = Join-Path $dir 'TranslucentTB.exe'
        Set-Autostart 'TranslucentTB' "`"$exe`""
        Start-Process $exe
    }

    'lively-install' {
        $setup = Get-GitHubAsset 'rocksdanister/lively' '^lively_setup_x86_full_.*\.exe$'
        Start-Process $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait
    }

    'lively-config' {
        $exe = Join-Path $env:ProgramFiles 'Lively Wallpaper\Lively.exe'
        if (-not (Test-Path $exe)) { throw "Lively is not installed: $exe" }
        Set-Autostart 'Lively' "`"$exe`""
        if (-not (Get-Process Lively -ErrorAction SilentlyContinue)) { Start-Process $exe }
        Wait-Until 30 { Get-Process Lively -ErrorAction SilentlyContinue } | Out-Null
        Start-Sleep -Seconds 10 # let Lively finish starting before it accepts commands
        $videos = [Environment]::GetFolderPath('MyVideos')
        $video = Join-Path $videos 'windows-xp-bliss-night.mp4'
        # Downloaded from its publisher instead of being redistributed in this repo
        Invoke-WebRequest -Uri 'https://cdn.livelywallpaper.app/wallpapers/windows-xp-bliss-night/download.mp4' -OutFile $video -UseBasicParsing
        Start-Process $exe -ArgumentList 'setwp', '--file', "`"$video`"" -Wait
    }

    'zen-install' {
        $setup = Get-GitHubAsset 'zen-browser/desktop' '^zen\.installer\.exe$'
        Start-Process $setup -ArgumentList '/S' -Wait
    }

    'zen-config' {
        $exe = Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'
        if (-not (Test-Path $exe)) { throw "Zen Browser is not installed: $exe" }
        $root = Join-Path $env:APPDATA 'zen'
        $ini = Join-Path $root 'profiles.ini'
        $hasInstallProfile = { (Test-Path $ini) -and (Select-String -Path $ini -Pattern '^\[Install' -Quiet) }
        if (-not (& $hasInstallProfile)) {
            # First headless run creates the default profile
            Get-Process zen -ErrorAction SilentlyContinue | Stop-Process -Force
            $zen = Start-Process $exe -ArgumentList '--headless' -PassThru
            Wait-Until 60 $hasInstallProfile | Out-Null
            Start-Sleep -Seconds 5
            Get-Process zen -ErrorAction SilentlyContinue | Stop-Process -Force
            $zen.WaitForExit()
        }
        # The [Install...] section names the profile Zen opens by default
        $lines = Get-Content $ini
        $start = ($lines | Select-String -Pattern '^\[Install' | Select-Object -First 1).LineNumber
        $default = $lines[$start..($lines.Count - 1)] | Where-Object { $_ -match '^Default=' } | Select-Object -First 1
        if (-not $default) { throw "No default Zen profile in $ini" }
        $profileDir = Join-Path $root ($default -replace '^Default=', '' -replace '/', '\')
        Get-Process zen -ErrorAction SilentlyContinue | Stop-Process -Force

        New-Item -ItemType Directory -Force (Join-Path $profileDir 'chrome'), (Join-Path $profileDir 'extensions') | Out-Null
        Copy-Item (Join-Path $Assets 'zen\userChrome.css') (Join-Path $profileDir 'chrome\userChrome.css') -Force
        Copy-Item (Join-Path $Assets 'zen\transparent-zen.xpi') (Join-Path $profileDir 'extensions\{74186d10-f6f2-4f73-b33a-83bb72e50654}.xpi') -Force
        # Keep prefs the user already has in user.js, ours win on conflicts
        $userJs = Join-Path $profileDir 'user.js'
        $ours = Get-Content (Join-Path $Assets 'zen\user.js')
        $names = $ours | ForEach-Object { if ($_ -match 'user_pref\("([^"]+)"') { $Matches[1] } }
        $kept = if (Test-Path $userJs) { Get-Content $userJs | Where-Object { -not ($_ -match 'user_pref\("([^"]+)"' -and $names -contains $Matches[1]) } } else { @() }
        [IO.File]::WriteAllLines($userJs, [string[]](@($kept) + $ours)) # UTF-8 without BOM
    }

    'widgets' {
        Get-Process WinWidgets -ErrorAction SilentlyContinue | Stop-Process -Force
        $setup = Get-GitHubAsset 'beyluta/WinWidgets' '_Installer\.exe$'
        Start-Process $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER' -Wait
        $exe = Join-Path $env:LOCALAPPDATA 'Programs\WinWidgets\WinWidgets.exe'
        if (-not (Test-Path $exe)) { throw "WinWidgets is not installed: $exe" }

        $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Widgets'
        New-Item -ItemType Directory -Force $dir | Out-Null
        $widget = Join-Path $dir 'ClockCalendar.html'
        Copy-Item (Join-Path $Assets 'widgets\ClockCalendar.html') $widget -Force
        $config = [ordered]@{
            version                        = '2.0.0'
            isWidgetAutostartEnabled       = $true
            isWidgetFullscreenHideEnabled  = $false
            isOpenAppOnStartupEnabled      = $true
            lastSessionWidgets             = @([ordered]@{ path = $widget -replace '\\', '/'; position = '730, 80'; alwaysOnTop = $false })
        }
        # WinWidgets expects UTF-8 without BOM
        [IO.File]::WriteAllText((Join-Path $dir 'config.json'), ($config | ConvertTo-Json -Depth 4 -Compress))
        Set-Autostart 'WinWidgets' "`"$exe`" --silent"
        Start-Process $exe -ArgumentList '--silent'
    }

    'flow' {
        $setup = Get-GitHubAsset 'Flow-Launcher/Flow.Launcher' '^Flow-Launcher-Setup\.exe$'
        Start-Process $setup -ArgumentList '--silent' -Wait
    }
}

Stop-Transcript | Out-Null
