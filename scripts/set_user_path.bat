@echo off
REM set_user_path.bat
REM English: This batch reads list.txt (if present) or uses the first argument
REM (semicolon-separated paths) and prepends missing entries into the user's PATH (HKCU).
REM Lines starting with '#' or empty lines in list.txt are ignored.
REM �ѱ���: �� ��ġ������ ���� ���͸��� list.txt(�����ϸ�)�� �аų�,
REM ����� ���ڷ� ���޵� �����ݷ�(;) ���� ��ε��� ����Ͽ�,
REM ����� ȯ�溯�� PATH(HKCU)�� ������ ��θ� �ߺ� ���� ����(prepend)���� �߰��մϴ�.
REM list.txt�� �� �ٰ� '#'���� �����ϴ� �ּ��� ���õ˴ϴ�.

setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "LISTFILE=%SCRIPT_DIR%list.txt"
set "ADDPATHS="
set "DRY_RUN=0"
if "%~1"=="--dry-run" (
  set "DRY_RUN=1"
  shift
)

if exist "%LISTFILE%" (
  REM list.txt�� �� �پ� �о� �� �ٰ� �ּ��� �����ϰ� �����ݷ� ���� ���ڿ��� ����
  REM English: read list.txt line-by-line, ignore blank and comment lines, build semicolon list
  for /f "usebackq delims=" %%L in ("%LISTFILE%") do (
    set "line=%%L"
    REM Trim leading spaces (tokens=* removes leading spaces)
    REM English: remove leading whitespace from the line
    for /f "tokens=*" %%A in ("!line!") do set "line=%%A"
    if not "!line!"=="" (
      REM '#'�� �����ϴ� �ּ� ���� ����
      REM English: ignore lines beginning with '#'
      echo !line! | findstr /b "#" >nul
      if errorlevel 1 (
        REM ���� �ý��ۿ� ��ΰ� �������� ������ ��� stderr�� ���(�׷��� ��Ͽ��� ����)
        REM English: warn if the listed path does not exist, but still include it
        if not exist "!line!\" ( 
          echo ���: ��Ͽ� ��õ� ��ΰ� �������� ����: !line! >&2
        )
        if defined ADDPATHS (
          set "ADDPATHS=!ADDPATHS!;!line!"
        ) else (
          set "ADDPATHS=!line!"
        )
      )
    )
  )
) else (
  if "%~1"=="" (
    echo ����: %~nx0 ^"C:\path1;C:\path2^"
    echo �Ǵ� �� ��ũ��Ʈ�� ������ ���͸��� �� �ٿ� �ϳ��� ��θ� ���� list.txt ������ �����ϼ���.
    echo English: Usage: %~nx0 "C:\path1;C:\path2"
    echo Or create a list.txt file with one path per line in the same directory as this script.
    exit /b 1
  )
  set "ADDPATHS=%~1"
)

REM Prepare temporary PowerShell script to update user PATH safely
REM Use a unique filename to avoid collisions when run in parallel or by multiple users.
REM Construct a sanitized timestamp stamp and include a random component.
set "STAMP=%DATE%_%TIME%"
rem remove characters that are invalid/unfriendly in filenames
set "STAMP=%STAMP::=%"
set "STAMP=%STAMP:.=%"
set "STAMP=%STAMP:/=%"
set "STAMP=%STAMP: =_%"
set "STAMP=%STAMP:,=%"
set "TMP_PS=%TEMP%\_set_user_path_tmp_%STAMP%_%RANDOM%.ps1"

rem Escape single quotes in ADDPATHS for embedding into PS script
set "PS_ADD=%ADDPATHS:'='''%"

if "%DRY_RUN%"=="1" (
  echo DRY RUN: temporary PowerShell filename would be:
  echo %TMP_PS%
  endlocal
  exit /b 0
)

>"%TMP_PS%" echo $add = '%PS_ADD%' -split ';' ^| Where-Object {$_ -ne ''}
>>"%TMP_PS%" echo $current_raw = [Environment]::GetEnvironmentVariable('Path','User')
>>"%TMP_PS%" echo if ([string]::IsNullOrEmpty($current_raw)) { $current = @() } else { $current = $current_raw -split ';' ^| Where-Object {$_ -ne ''} }
>>"%TMP_PS%" echo foreach ($p in $add) { if (-not ($current -contains $p)) { $current = ,$p + $current } }
>>"%TMP_PS%" echo $newPath = ($current -join ';')
>>"%TMP_PS%" echo [Environment]::SetEnvironmentVariable('Path',$newPath,'User')
>>"%TMP_PS%" echo Write-Host '����� PATH�� ������Ʈ�Ǿ����ϴ� (���� �׸�):'
>>"%TMP_PS%" echo $current[0..([math]::Min(9,$current.Count-1))] ^| ForEach-Object { Write-Host "  $_" }
>>"%TMP_PS%" echo ""
>>"%TMP_PS%" echo # Broadcast WM_SETTINGCHANGE so Explorer and other apps pick up the change
>>"%TMP_PS%" echo $signature = @"
>>"%TMP_PS%" echo using System;
>>"%TMP_PS%" echo using System.Runtime.InteropServices;
>>"%TMP_PS%" echo public class NativeMethods {
>>"%TMP_PS%" echo     [DllImport(^"user32.dll^", CharSet = CharSet.Auto)]
>>"%TMP_PS%" echo     public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
>>"%TMP_PS%" echo }
>>"%TMP_PS%" echo "@
>>"%TMP_PS%" echo Add-Type -TypeDefinition $signature -ErrorAction Stop
>>"%TMP_PS%" echo $HWND_BROADCAST = [IntPtr]0xffff
>>"%TMP_PS%" echo $WM_SETTINGCHANGE = 0x001A
>>"%TMP_PS%" echo [UIntPtr]$result = [UIntPtr]::Zero
>>"%TMP_PS%" echo [NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 0, 5000, [ref]$result) ^| Out-Null
>>"%TMP_PS%" echo Write-Host 'ȯ�溯�� ������ ��ε�ĳ��Ʈ�߽��ϴ� (WM_SETTINGCHANGE).' -ForegroundColor Cyan

REM Run the temporary PowerShell script (bypass execution policy for this run)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS%"

REM Remove temporary script
del /f /q "%TMP_PS%" >nul 2>&1

endlocal
echo Done.
exit /b 0
