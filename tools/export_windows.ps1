$ErrorActionPreference = "Stop"
$Project = Split-Path -Parent $PSScriptRoot
Set-Location $Project
$Godot = "C:\Users\jerky\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path $Godot)) {
	$cmd = Get-Command godot -ErrorAction SilentlyContinue
	if ($cmd) { $Godot = $cmd.Source }
}
if (-not (Test-Path $Godot)) {
	throw "Godot 4.7.2 editor not found."
}
$OutDir = Join-Path $Project "export\windows"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "Exporting with $Godot"
& $Godot --headless --path "." --export-release "Windows Desktop" "export/windows/DeepSnakes3D.exe"
$exe = Join-Path $OutDir "DeepSnakes3D.exe"
if (-not (Test-Path $exe)) {
	throw "Export finished but $exe is missing."
}
$zip = Join-Path $OutDir "DeepSnakes3D-windows.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
$files = Get-ChildItem $OutDir -File | Where-Object { $_.Extension -ne ".zip" }
Compress-Archive -Path $files.FullName -DestinationPath $zip -Force
Write-Host "Wrote $zip"
