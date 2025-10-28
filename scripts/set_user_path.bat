@echo off
REM set_user_path.bat
REM English: This batch reads list.txt (if present) or uses the first argument
REM (semicolon-separated paths) and prepends missing entries into the user's PATH (HKCU).
REM Lines starting with '#' or empty lines in list.txt are ignored.
REM 한국어: 이 배치파일은 동일 디렉터리의 list.txt(존재하면)를 읽거나,
REM 명령행 인자로 전달된 세미콜론(;) 구분 경로들을 사용하여,
REM 사용자 환경변수 PATH(HKCU)에 누락된 경로를 중복 없이 선행(prepend)으로 추가합니다.
REM list.txt의 빈 줄과 '#'으로 시작하는 주석은 무시됩니다.

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
  REM list.txt을 한 줄씩 읽어 빈 줄과 주석을 무시하고 세미콜론 구분 문자열을 구성
  REM English: read list.txt line-by-line, ignore blank and comment lines, build semicolon list
  for /f "usebackq delims=" %%L in ("%LISTFILE%") do (
    set "line=%%L"
    REM Trim leading spaces (tokens=* removes leading spaces)
    REM English: remove leading whitespace from the line
    for /f "tokens=*" %%A in ("!line!") do set "line=%%A"
    if not "!line!"=="" (
      REM '#'로 시작하는 주석 라인 무시
      REM English: ignore lines beginning with '#'
      echo !line! | findstr /b "#" >nul
      if errorlevel 1 (
        REM 파일 시스템에 경로가 존재하지 않으면 경고를 stderr로 출력(그러나 목록에는 포함)
        REM English: warn if the listed path does not exist, but still include it
        if not exist "!line!\" ( 
          echo 경고: 목록에 명시된 경로가 존재하지 않음: !line! >&2
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
    echo 사용법: %~nx0 ^"C:\path1;C:\path2^"
    echo 또는 이 스크립트와 동일한 디렉터리에 한 줄에 하나씩 경로를 적은 list.txt 파일을 생성하세요.
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
>>"%TMP_PS%" echo Write-Host '사용자 PATH가 업데이트되었습니다 (상위 항목):'
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
>>"%TMP_PS%" echo Write-Host '환경변수 변경을 브로드캐스트했습니다 (WM_SETTINGCHANGE).' -ForegroundColor Cyan

REM Run the temporary PowerShell script (bypass execution policy for this run)
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS%"

REM Remove temporary script
del /f /q "%TMP_PS%" >nul 2>&1

endlocal
echo Done.
exit /b 0
