param(
	[switch]$MixOnly
)
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
$RawDir = Join-Path $Project "export\trailer"
$OutDir = Join-Path $Project "docs\trailer"
$VoDir = Join-Path $RawDir "vo"
New-Item -ItemType Directory -Force -Path $RawDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Avi = Join-Path $RawDir "raw.avi"
$Mp4 = Join-Path $OutDir "deepsnakes-trailer.mp4"

function Invoke-VoiceoverMix([string]$VideoIn, [string]$VideoOut) {
	python (Join-Path $PSScriptRoot "generate_voiceover.py")
	$delays = @(600, 2400, 8500, 28500, 48500, 68500, 88500, 108500)
	$ffArgs = @("-y", "-i", $VideoIn)
	foreach ($i in 0..7) {
		$clip = Join-Path $VoDir ("line_{0:d2}.mp3" -f $i)
		if (-not (Test-Path $clip)) { throw "Missing voiceover clip $clip" }
		$ffArgs += @("-i", $clip)
	}
	$parts = New-Object System.Collections.Generic.List[string]
	$parts.Add("[0:a]volume=0.20[sfx]")
	$mix = "[sfx]"
	for ($i = 0; $i -lt 8; $i++) {
		$idx = $i + 1
		$lab = "v$i"
		$d = $delays[$i]
		$parts.Add("[$idx`:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,highpass=f=70,volume=3.0,adelay=${d}|${d}[$lab]")
		$mix += "[$lab]"
	}
	$parts.Add("${mix}amix=inputs=9:duration=first:dropout_transition=2:normalize=0[aout]")
	$filter = ($parts -join ";")
	$ffArgs += @(
		"-filter_complex", $filter,
		"-map", "0:v",
		"-map", "[aout]",
		"-c:v", "copy",
		"-c:a", "aac",
		"-b:a", "192k",
		"-movflags", "+faststart",
		$VideoOut
	)
	& ffmpeg @ffArgs
	if ($LASTEXITCODE -ne 0 -and -not (Test-Path $VideoOut)) {
		throw "Voiceover mix failed."
	}
}

if ($MixOnly) {
	if (-not (Test-Path $Mp4)) { throw "Missing $Mp4" }
	$tmp = Join-Path $OutDir "deepsnakes-trailer-vo.mp4"
	Invoke-VoiceoverMix $Mp4 $tmp
	Move-Item -Force $tmp $Mp4
	Write-Host "Wrote $Mp4 with voiceover"
	Get-Item $Mp4 | Select-Object FullName, Length
	exit 0
}

if (Test-Path $Avi) { Remove-Item $Avi -Force }
Write-Host "Recording trailer with Movie Maker..."
& $Godot --path "." --fixed-fps 30 --write-movie "export/trailer/raw.avi" "res://tools/trailer_director.tscn"
if (-not (Test-Path $Avi)) {
	throw "Movie Maker did not write $Avi"
}
$silent = Join-Path $OutDir "deepsnakes-trailer-silent.mp4"
& ffmpeg -y -i $Avi -vf "scale=1280:-2,fps=30" -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 160k -movflags +faststart $silent
if (-not (Test-Path $silent)) { throw "ffmpeg video encode failed." }
Invoke-VoiceoverMix $silent $Mp4
Remove-Item $silent -ErrorAction SilentlyContinue
Write-Host "Wrote $Mp4"
Get-Item $Mp4 | Select-Object FullName, Length
