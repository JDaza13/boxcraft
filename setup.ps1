# ============================================================
#  setup.ps1 — Check and install prerequisites
#  Run from PowerShell: .\setup.ps1
# ============================================================

# --- Virtualization precheck ---
Write-Host ""
Write-Host "Checking virtualization..." -ForegroundColor Cyan
Write-Host ""

$cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
if (-not $cpu) {
    Write-Host "  [!] Could not query CPU info -- skipping virtualization check." -ForegroundColor Yellow
} elseif ($cpu.VirtualizationFirmwareEnabled) {
    Write-Host "  [ok] Virtualization   enabled in firmware" -ForegroundColor Green
} else {
    Write-Host "  [!!] Virtualization is NOT enabled in firmware." -ForegroundColor Red
    Write-Host ""
    Write-Host "  VirtualBox requires Intel VT-x or AMD-V to be enabled in your BIOS/UEFI."
    Write-Host "  Reboot, enter BIOS/UEFI settings, and enable the virtualization option"
    Write-Host "  (often listed as 'Intel Virtualization Technology', 'VT-x', or 'SVM Mode')."
    Write-Host ""
    exit 1
}

Write-Host ""

# --- Tool prerequisites ---
$tools = @(
    @{ Name = "VirtualBox"; WingetId = "Oracle.VirtualBox";  Command = "VBoxManage" },
    @{ Name = "Vagrant";    WingetId = "HashiCorp.Vagrant";   Command = "vagrant"    },
    @{ Name = "Packer";     WingetId = "HashiCorp.Packer";    Command = "packer"     },
    @{ Name = "Git";        WingetId = "Git.Git";             Command = "git"        },
    @{ Name = "GitHub CLI"; WingetId = "GitHub.cli";          Command = "gh"         }
)

$toInstall = @()

Write-Host ""
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
Write-Host ""

$vboxFallback = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

foreach ($tool in $tools) {
    $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
    if (-not $cmd -and $tool.Command -eq "VBoxManage" -and (Test-Path $vboxFallback)) {
        $cmd = $vboxFallback
    }
    if ($cmd) {
        $exe = if ($cmd -is [string]) { $cmd } else { $tool.Command }
        $version = (& $exe --version 2>$null) | Select-Object -First 1
        Write-Host "  [ok] $($tool.Name.PadRight(12)) $version" -ForegroundColor Green
    } else {
        Write-Host "  [--] $($tool.Name.PadRight(12)) not found" -ForegroundColor Yellow
        $toInstall += $tool
    }
}

Write-Host ""

if ($toInstall.Count -eq 0) {
    Write-Host "All prerequisites are installed. You're good to go." -ForegroundColor Green
    Write-Host ""
    Write-Host "  cd ubuntu && vagrant up"
    Write-Host "  cd mint   && vagrant up"
    Write-Host ""
    exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found." -ForegroundColor Red
    Write-Host "Install 'App Installer' from the Microsoft Store and re-run this script."
    Write-Host ""
    exit 1
}

Write-Host "Installing missing tools via winget..." -ForegroundColor Cyan
Write-Host ""

$failed = @()
foreach ($tool in $toInstall) {
    Write-Host "  Installing $($tool.Name)..." -ForegroundColor Yellow
    winget install --id $tool.WingetId --accept-source-agreements --accept-package-agreements --silent
    # 0x8A150013 (-1978335189) = no upgrade available (already up to date) — treat as success
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        Write-Host "  [!] $($tool.Name) install may have failed (exit $LASTEXITCODE)" -ForegroundColor Red
        $failed += $tool.Name
    } else {
        Write-Host "  [ok] $($tool.Name) installed" -ForegroundColor Green
    }
    Write-Host ""
}

if ($failed.Count -gt 0) {
    Write-Host "Some installs failed: $($failed -join ', ')" -ForegroundColor Red
    Write-Host "Try installing them manually from their websites."
    Write-Host ""
    exit 1
}

Write-Host "Done. Restart your terminal so PATH changes take effect, then:" -ForegroundColor Green
Write-Host ""
Write-Host "  cd ubuntu && vagrant up"
Write-Host "  cd mint   && vagrant up"
Write-Host ""
