param([string]$DeviceId)
$ErrorActionPreference = 'Stop'
$eselFlutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $eselFlutter) { throw 'Flutter SDK를 PATH에 등록한 뒤 다시 실행해 주세요.' }
$eselAppDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'flutter_app'
Push-Location -LiteralPath $eselAppDirectory
try {
  & $eselFlutter.Source pub get
  if ($LASTEXITCODE -ne 0) { throw 'Flutter 패키지 준비에 실패했습니다.' }
  if ($DeviceId) {
    & $eselFlutter.Source run -d $DeviceId --dart-define=ESEL_API_MODE=mock
  } else {
    & $eselFlutter.Source run --dart-define=ESEL_API_MODE=mock
  }
} finally { Pop-Location }
