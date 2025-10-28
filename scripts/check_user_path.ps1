<#
check_user_path.ps1

English: This script reads paths from a list.txt file in the same directory and
verifies whether each path exists in the current user's PATH environment variable (HKCU\Environment).
It returns exit code 0 if all paths are present, 1 if some are missing, and 2 if list.txt is missing or empty.

Korean: �� ��ũ��Ʈ�� ���� ���͸��� list.txt ���Ͽ��� ��θ� �о��
���� ������� PATH ȯ�溯��(HKCU\Environment)�� �ش� ��ε��� �����ϴ��� �˻��մϴ�.
��� �����ϸ� �����ڵ� 0, �Ϻ� �����̸� 1, list.txt�� ���ų� ��������� 2�� ��ȯ�մϴ�.

Usage / ����:
    PowerShell (from workspace folder / ��ũ�����̽� ��������):
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        .\check_user_path.ps1
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$listFile = Join-Path $scriptDir 'list.txt'

if (-not (Test-Path $listFile)) {
    Write-Host "list.txt ������ ã�� �� �����ϴ�: $listFile" -ForegroundColor Yellow
    exit 2
}

# Read lines, ignore blank and commented lines. Normalize for comparison.
# English: load list.txt and ignore blank/comment lines
# Korean: list.txt�� �о� �� �ٰ� �ּ� ������ �����մϴ�
$lines = Get-Content $listFile | ForEach-Object { $_.Trim() } | Where-Object { ($_ -ne '') -and (-not $_.StartsWith('#')) }
if ($lines.Count -eq 0) {
    Write-Host "list.txt �� ��ȿ�� ��ΰ� �����ϴ�." -ForegroundColor Yellow
    exit 2
}

# Normalize function: trim and remove trailing backslash, use lowercase for comparison
function Normalize-Path([string]$p) {
    # English: normalize path for comparison: trim, remove trailing backslash, lowercase
    # �ѱ���: ��� �񱳸� ���� ����ȭ�մϴ�(��������, ���� �齽���� ����, �ҹ���ȭ)
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
Write-Host "list.txt�� ��õ� ��ε��� ����� PATH�� �ִ��� Ȯ���մϴ�:`n" -ForegroundColor Cyan
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
    Write-Host "`n��� ��ΰ� ����� PATH�� �����մϴ�." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n�Ϻ� ��ΰ� ����� PATH�� �����ϴ�." -ForegroundColor Yellow
    Write-Host "list.txt�� ��ε��� �߰��Ϸ���: .\set_user_path.bat �� �����ϼ���." -ForegroundColor Cyan
    exit 1
}
