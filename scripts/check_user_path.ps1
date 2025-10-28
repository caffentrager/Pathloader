<#
check_user_path.ps1

English: This script reads paths from a list.txt file in the same directory and
verifies whether each path exists in the current user's PATH environment variable (HKCU\Environment).
It returns exit code 0 if all paths are present, 1 if some are missing, and 2 if list.txt is missing or empty.

Korean: 이 스크립트는 동일 디렉터리의 list.txt 파일에서 경로를 읽어와
현재 사용자의 PATH 환경변수(HKCU\Environment)에 해당 경로들이 존재하는지 검사합니다.
모두 존재하면 종료코드 0, 일부 누락이면 1, list.txt가 없거나 비어있으면 2를 반환합니다.

Usage / 사용법:
    PowerShell (from workspace folder / 워크스페이스 폴더에서):
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\check_user_path.ps1
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listFile = Join-Path $scriptDir 'list.txt'

if (-not (Test-Path $listFile)) {
    Write-Host "list.txt 파일을 찾을 수 없습니다: $listFile" -ForegroundColor Yellow
    exit 2
}

# Read lines, ignore blank and commented lines. Normalize for comparison.
# English: load list.txt and ignore blank/comment lines
# Korean: list.txt을 읽어 빈 줄과 주석 라인을 무시합니다
$lines = Get-Content $listFile | ForEach-Object { $_.Trim() } | Where-Object { ($_ -ne '') -and (-not $_.StartsWith('#')) }
if ($lines.Count -eq 0) {
    Write-Host "list.txt 에 유효한 경로가 없습니다." -ForegroundColor Yellow
    exit 2
}

# Normalize function: trim and remove trailing backslash, use lowercase for comparison
function Normalize-Path([string]$p) {
    # English: normalize path for comparison: trim, remove trailing backslash, lowercase
    # 한국어: 경로 비교를 위해 정규화합니다(공백제거, 후행 백슬래시 제거, 소문자화)
    if ([string]::IsNullOrWhiteSpace($p)) { return '' }
    $t = $p.Trim()
    # remove trailing backslashes for stable comparison
    $t = $t.TrimEnd('\\')
    return $t.ToLowerInvariant()
}

$userPathRaw = [Environment]::GetEnvironmentVariable('Path','User')
$userPathList = @()
if (-not [string]::IsNullOrEmpty($userPathRaw)) {
    $userPathList = $userPathRaw -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}

# Build a hashset of normalized user PATH entries for fast, case-insensitive lookup
$userSet = @{}
foreach ($u in $userPathList) { $userSet[(Normalize-Path $u)] = $true }

$allPresent = $true
Write-Host "list.txt에 명시된 경로들이 사용자 PATH에 있는지 확인합니다:`n" -ForegroundColor Cyan
foreach ($p in $lines) {
    $norm = Normalize-Path $p
    if ($norm -ne '' -and $userSet.ContainsKey($norm)) {
        Write-Host "[OK]   $p" -ForegroundColor Green
    } else {
        Write-Host "[MISS] $p" -ForegroundColor Red
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Host "`n모든 경로가 사용자 PATH에 존재합니다." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n일부 경로가 사용자 PATH에 없습니다." -ForegroundColor Yellow
    Write-Host "list.txt의 경로들을 추가하려면: .\set_user_path.bat 를 실행하세요." -ForegroundColor Cyan
    exit 1
}
