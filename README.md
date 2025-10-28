Pathloader - Windows 사용자 PATH(HKCU) 관리 유틸리티

간단한 설명
Pathloader는 Windows에서 사용자 수준(HKCU)의 PATH 환경변수를 쉽게 관리하도록 돕는 작은 스크립트 모음입니다.
`scripts/list.txt`에 도구의 bin 경로를 적고, 체크 스크립트로 누락 여부를 확인한 뒤 배치 파일로 누락된 항목을 사용자 PATH에 추가하는 흐름으로 설계되어 있습니다.

주요 파일
- `scripts/check_user_path.ps1`  - `list.txt`에 명시된 경로들이 사용자 PATH에 있는지 검사합니다.
- `scripts/set_user_path.bat`    - `list.txt` 또는 명령행 인자로 전달된 세미콜론(;) 구분 경로들을 사용자 PATH에 선행(prepend)으로 추가합니다.
- `scripts/list.txt`             - 예시 경로 목록(한 줄에 하나, `#`으로 주석 처리 가능).
- `.github/workflows/ci.yml`     - (옵션) Windows runner에서 체크 스크립트를 실행하도록 구성된 예시 워크플로.
- `LICENSE`, `.gitignore`        - 라이선스와 git 무시 규칙.

빠른 시작 (Quick start)
1) 저장소 가져오기
   - 이 폴더를 원하는 위치로 복사하거나 GitHub에서 클론하세요. 예: `D:\Pathloader`

2) 경로 목록 편집
   - `scripts/list.txt`에 추가하려는 도구의 bin 디렉터리를 한 줄에 하나씩 적습니다.
     예: `C:\msys64\mingw64\bin` 또는 `C:\ProgramData\chocolatey\bin`

3) 검사 (PowerShell)
   - PowerShell에서(저장소 루트):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\check_user_path.ps1
```

   - 스크립트는 모든 항목이 존재하면 종료코드 0, 일부 누락이면 1, `list.txt`가 없거나 비어있으면 2를 반환합니다.

4) 누락 항목 추가
   - `set_user_path.bat`는 두 가지 방식으로 동작합니다:
     - `scripts/list.txt`가 존재하면 그 내용을 사용
     - 존재하지 않으면 배치 파일의 첫 번째 인자에서 세미콜론(;)으로 구분된 경로 문자열을 사용

   - 예 (명령 프롬프트):

```bat
cd D:\Pathloader\scripts
set_user_path.bat "C:\custom\bin;C:\another\bin"
```

   - 예 (PowerShell):

```powershell
cd D:\Pathloader\scripts
.\n+# 또는 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass & .\set_user_path.bat "C:\custom\bin;C:\another\bin"
```

5) 변경 확인
   - 새 PowerShell 창을 열고 `$env:Path` 또는 `Get-ChildItem env:Path`로 반영 여부를 확인하세요.

안전 및 주의사항
- 권한: 이 스크립트는 사용자 수준(HKCU)을 수정하므로 관리자 권한이 필요하지 않습니다.
- 실행 정책: `set_user_path.bat`는 내부적으로 임시 PowerShell 스크립트를 생성하고 `-ExecutionPolicy Bypass`로 실행합니다. 조직의 보안정책에 따라 제한될 수 있습니다.
- 임시 파일 충돌 예방: 배치 파일은 `%TEMP%`에 임시 PS 스크립트를 생성합니다. 동일한 이름의 충돌 가능성을 줄이기 위해(예: 프로세스 ID 또는 타임스탬프를 포함한 이름 사용)을 권장합니다. (현재 배치파일에서는 `_set_user_path_tmp.ps1`을 사용합니다.)
- 백업 권장: 대규모 변경 전에 현재 사용자 PATH를 백업하세요. PowerShell에서 예: `[Environment]::GetEnvironmentVariable('Path','User') | Out-File user_path_backup.txt`.
- 브로드캐스트 제한: 스크립트는 WM_SETTINGCHANGE를 전송하여 Explorer 등에게 알리지만, 이미 실행 중인 일부 프로그램은 변경을 인식하려면 재시작이 필요할 수 있습니다.

팁 및 확장 제안
- 존재하는 경로만 추가하도록 하는 옵션(예: `--exist-only`) 또는 삽입 방식(append vs prepend) 옵션을 추가하면 안전성과 유연성이 올라갑니다.
- 경로 정규화 개선(심볼릭 링크, NT 경로, 환경변수 확장 등)을 `check_user_path.ps1`에 추가하면 더 강건한 비교가 가능합니다.

CI
- `.github/workflows/ci.yml`는 예시로 Windows runner에서 `check_user_path.ps1`을 실행합니다. CI 환경의 PATH는 로컬과 다를 수 있으므로, 실제 PATH 변경(예: `set_user_path.bat`)은 로컬에서 실행해야 합니다.

라이선스
- 이 프로젝트는 MIT 라이선스로 배포됩니다(파일 `LICENSE` 참고).

피드백 / 기여
- 사용 중 개선점이나 추가 기능(예: 임시 파일명 충돌 제거, `--exist-only` 옵션, 더 정교한 정규화)이 필요하면 이슈나 PR을 열어주세요.

---
English summary (short)
Pathloader provides simple scripts to manage the user PATH on Windows. Edit `scripts/list.txt`, run the checker, and use the batch script to add missing tool paths. See the README for additional notes about usage, safety and suggestions for enhancements.
