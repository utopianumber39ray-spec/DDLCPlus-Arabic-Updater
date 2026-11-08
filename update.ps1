# DDLC+ Arabic Updater - Windows PowerShell 5+
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root 'files'
$exeName = 'Doki Doki Literature Club Plus.exe'
$files = @(
  'Doki Doki Literature Club Plus_Data\Managed\DDLC.dll',
  'Doki Doki Literature Club Plus_Data\Managed\TextTypewriterEffect.dll',
  'Doki Doki Literature Club Plus_Data\Managed\ArabicShaper.dll',
  'Doki Doki Literature Club Plus_Data\Managed\Unity.TextMeshPro.dll'
)

if (-not (Test-Path -LiteralPath $src)) {
  Write-Host 'ERROR: the files folder is missing next to this script.' -ForegroundColor Red
  exit 1
}
foreach ($rel in $files) {
  if (-not (Test-Path -LiteralPath (Join-Path $src $rel))) {
    Write-Host ('ERROR: missing file: ' + $rel) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
  }
}

if (Get-Process -Name 'Doki Doki Literature Club Plus' -ErrorAction SilentlyContinue) {
  Write-Host 'Close the game first, then run update.bat again.' -ForegroundColor Red
  exit 1
}

function Find-Game([string]$path) {
  if ([string]::IsNullOrWhiteSpace($path)) { return $null }
  $p = $path.Trim().Trim('"')
  if (Test-Path -LiteralPath (Join-Path $p $exeName)) { return $p }
  return $null
}

$candidates = New-Object System.Collections.Generic.List[string]
$candidates.Add($root)
$candidates.Add((Get-Location).Path)
$steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
if ($steam) {
  $steam = $steam -replace '/', '\'
  $candidates.Add((Join-Path $steam 'steamapps\common\Doki Doki Literature Club Plus'))
  $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
  if (Test-Path -LiteralPath $vdf) {
    foreach ($line in Get-Content -LiteralPath $vdf) {
      if ($line -match '"path"\s+"(.+?)"') {
        $lib = $matches[1] -replace '\\\\', '\'
        $candidates.Add((Join-Path $lib 'steamapps\common\Doki Doki Literature Club Plus'))
      }
    }
  }
}
$candidates.Add('C:\Program Files (x86)\Steam\steamapps\common\Doki Doki Literature Club Plus')
$candidates.Add('C:\Program Files\Steam\steamapps\common\Doki Doki Literature Club Plus')
$game = $null
foreach ($c in $candidates) {
  if (-not $c) { continue }
  $p = $c.Trim().Trim('"')
  if (Test-Path -LiteralPath (Join-Path $p $exeName)) { $game = $p; break }
}
if (-not $game) {
  Write-Host 'Paste the folder that contains Doki Doki Literature Club Plus.exe'
  $answer = Read-Host 'Game folder'
  $p = $answer.Trim().Trim('"')
  if (-not (Test-Path -LiteralPath (Join-Path $p $exeName))) {
    Write-Host 'The game executable was not found in that folder.' -ForegroundColor Red
    exit 1
  }
  $game = $p
}

$backup = Join-Path $game '_DDLCPlus_Arabic_Update_Backup'
New-Item -ItemType Directory -Force -Path $backup | Out-Null
foreach ($rel in $files) {
  $dest = Join-Path $game $rel
  $back = Join-Path $backup $rel
  if (Test-Path -LiteralPath $dest) {
    if (-not (Test-Path -LiteralPath $back)) {
      New-Item -ItemType Directory -Force -Path (Split-Path -Parent $back) | Out-Null
      Copy-Item -LiteralPath $dest -Destination $back -Force
    }
  } else {
    Add-Content -LiteralPath (Join-Path $backup 'absent.txt') -Value $rel -Encoding UTF8
  }
}

foreach ($rel in $files) {
  $source = Join-Path $src $rel
  $dest = Join-Path $game $rel
  if (-not (Test-Path -LiteralPath $source)) {
    Write-Host ('ERROR: missing file: ' + $rel) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
  }
  $parent = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath (Split-Path -Parent $dest))) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
  }
  Copy-Item -LiteralPath $source -Destination $dest -Force
  $expected = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
  $actual = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
  if ($expected -ne $actual) {
    Write-Host ('ERROR: verification failed: ' + $rel) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
  }
  Write-Host ('Updated: ' + $rel)
}
Write-Host ''
Write-Host 'Done. All localization files were updated.'
exit 0
