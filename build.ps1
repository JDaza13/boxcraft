# ============================================================
#  build.ps1 — Pre-bake a Packer base image for a profile
#
#  Usage:
#    .\build.ps1 ubuntu
#    .\build.ps1 mint
#
#  What it does:
#    1. Runs Packer to build a pre-installed .box (~20 min, once)
#    2. Registers the box with Vagrant as boxcraft/<profile>
#    3. Writes a sentinel so the Vagrantfile auto-uses the baked box
#
#  After this, `vagrant up` boots in ~2 min instead of ~15 min.
# ============================================================
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ubuntu", "mint")]
    [string]$Profile
)

$ErrorActionPreference = "Stop"
$ProfileDir = Join-Path $PSScriptRoot $Profile
$BoxName    = "boxcraft/$Profile"
$PackerFile = Join-Path $ProfileDir "${Profile}.pkr.hcl"
$BuildsDir  = Join-Path $ProfileDir "builds"

Write-Host ""
Write-Host "==> Building Packer image for '$Profile'" -ForegroundColor Cyan
Write-Host "    This takes ~20 minutes. Go get a coffee." -ForegroundColor Yellow
Write-Host ""

Push-Location $ProfileDir

try {
    # Initialise Packer plugins
    Write-Host "==> Initialising Packer plugins..." -ForegroundColor Cyan
    packer init $PackerFile
    if ($LASTEXITCODE -ne 0) { throw "packer init failed (exit $LASTEXITCODE)" }

    # Validate config before spending 20 min on a broken build
    Write-Host ""
    Write-Host "==> Validating Packer config..." -ForegroundColor Cyan
    packer validate $PackerFile
    if ($LASTEXITCODE -ne 0) { throw "packer validate failed (exit $LASTEXITCODE) -- check the .pkr.hcl file" }

    # Build the box
    Write-Host ""
    Write-Host "==> Running Packer build..." -ForegroundColor Cyan
    packer build -force $PackerFile
    if ($LASTEXITCODE -ne 0) { throw "packer build failed (exit $LASTEXITCODE) -- scroll up for the full packer output" }

    # Find the output .box file
    $boxFile = Get-ChildItem -Path $BuildsDir -Filter "*.box" -ErrorAction Stop |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1 -ExpandProperty FullName

    if (-not $boxFile) { throw "No .box file found in $BuildsDir" }

    # Register with Vagrant
    Write-Host ""
    Write-Host "==> Registering '$BoxName' with Vagrant..." -ForegroundColor Cyan
    vagrant box add --name $BoxName $boxFile --force
    if ($LASTEXITCODE -ne 0) { throw "vagrant box add failed" }

    # Write sentinel so the Vagrantfile detects the baked box
    $vagrantDir = Join-Path $ProfileDir ".vagrant"
    New-Item -ItemType Directory -Force -Path $vagrantDir | Out-Null
    Set-Content -Path (Join-Path $vagrantDir "packer_built") -Value $BoxName -Encoding utf8

    Write-Host ""
    Write-Host "==> Done! Box '$BoxName' is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "    cd $Profile"
    Write-Host "    vagrant up"
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "==> Build failed: $_" -ForegroundColor Red
    Write-Host ""
    exit 1
} finally {
    Pop-Location
}
