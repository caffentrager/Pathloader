Pathloader - Windows ����� PATH(HKCU) ���� ��ƿ��Ƽ

������ ����
Pathloader�� Windows���� ����� ����(HKCU)�� PATH ȯ�溯���� ���� �����ϵ��� ���� ���� ��ũ��Ʈ �����Դϴ�.
`scripts/list.txt`�� ������ bin ��θ� ����, üũ ��ũ��Ʈ�� ���� ���θ� Ȯ���� �� ��ġ ���Ϸ� ������ �׸��� ����� PATH�� �߰��ϴ� �帧���� ����Ǿ� �ֽ��ϴ�.

�ֿ� ����
- `scripts/check_user_path.ps1`  - `list.txt`�� ��õ� ��ε��� ����� PATH�� �ִ��� �˻��մϴ�.
- `scripts/set_user_path.bat`    - `list.txt` �Ǵ� ����� ���ڷ� ���޵� �����ݷ�(;) ���� ��ε��� ����� PATH�� ����(prepend)���� �߰��մϴ�.
- `scripts/list.txt`             - ���� ��� ���(�� �ٿ� �ϳ�, `#`���� �ּ� ó�� ����).
- `.github/workflows/ci.yml`     - (�ɼ�) Windows runner���� üũ ��ũ��Ʈ�� �����ϵ��� ������ ���� ��ũ�÷�.
- `LICENSE`, `.gitignore`        - ���̼����� git ���� ��Ģ.

���� ���� (Quick start)
1) ����� ��������
   - �� ������ ���ϴ� ��ġ�� �����ϰų� GitHub���� Ŭ���ϼ���. ��: `D:\Pathloader`

2) ��� ��� ����
   - `scripts/list.txt`�� �߰��Ϸ��� ������ bin ���͸��� �� �ٿ� �ϳ��� �����ϴ�.
     ��: `C:\msys64\mingw64\bin` �Ǵ� `C:\ProgramData\chocolatey\bin`

3) �˻� (PowerShell)
   - PowerShell����(����� ��Ʈ):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\check_user_path.ps1
```

   - ��ũ��Ʈ�� ��� �׸��� �����ϸ� �����ڵ� 0, �Ϻ� �����̸� 1, `list.txt`�� ���ų� ��������� 2�� ��ȯ�մϴ�.

4) ���� �׸� �߰�
   - `set_user_path.bat`�� �� ���� ������� �����մϴ�:
     - `scripts/list.txt`�� �����ϸ� �� ������ ���
     - �������� ������ ��ġ ������ ù ��° ���ڿ��� �����ݷ�(;)���� ���е� ��� ���ڿ��� ���

   - �� (��� ������Ʈ):

```bat
cd D:\Pathloader\scripts
set_user_path.bat "C:\custom\bin;C:\another\bin"
```

   - �� (PowerShell):

```powershell
cd D:\Pathloader\scripts
.\n+# �Ǵ� Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass & .\set_user_path.bat "C:\custom\bin;C:\another\bin"
```

5) ���� Ȯ��
   - �� PowerShell â�� ���� `$env:Path` �Ǵ� `Get-ChildItem env:Path`�� �ݿ� ���θ� Ȯ���ϼ���.

���� �� ���ǻ���
- ����: �� ��ũ��Ʈ�� ����� ����(HKCU)�� �����ϹǷ� ������ ������ �ʿ����� �ʽ��ϴ�.
- ���� ��å: `set_user_path.bat`�� ���������� �ӽ� PowerShell ��ũ��Ʈ�� �����ϰ� `-ExecutionPolicy Bypass`�� �����մϴ�. ������ ������å�� ���� ���ѵ� �� �ֽ��ϴ�.
- �ӽ� ���� �浹 ����: ��ġ ������ `%TEMP%`�� �ӽ� PS ��ũ��Ʈ�� �����մϴ�. ������ �̸��� �浹 ���ɼ��� ���̱� ����(��: ���μ��� ID �Ǵ� Ÿ�ӽ������� ������ �̸� ���)�� �����մϴ�. (���� ��ġ���Ͽ����� `_set_user_path_tmp.ps1`�� ����մϴ�.)
- ��� ����: ��Ը� ���� ���� ���� ����� PATH�� ����ϼ���. PowerShell���� ��: `[Environment]::GetEnvironmentVariable('Path','User') | Out-File user_path_backup.txt`.
- ��ε�ĳ��Ʈ ����: ��ũ��Ʈ�� WM_SETTINGCHANGE�� �����Ͽ� Explorer ��� �˸�����, �̹� ���� ���� �Ϻ� ���α׷��� ������ �ν��Ϸ��� ������� �ʿ��� �� �ֽ��ϴ�.

�� �� Ȯ�� ����
- �����ϴ� ��θ� �߰��ϵ��� �ϴ� �ɼ�(��: `--exist-only`) �Ǵ� ���� ���(append vs prepend) �ɼ��� �߰��ϸ� �������� �������� �ö󰩴ϴ�.
- ��� ����ȭ ����(�ɺ��� ��ũ, NT ���, ȯ�溯�� Ȯ�� ��)�� `check_user_path.ps1`�� �߰��ϸ� �� ������ �񱳰� �����մϴ�.

CI
- `.github/workflows/ci.yml`�� ���÷� Windows runner���� `check_user_path.ps1`�� �����մϴ�. CI ȯ���� PATH�� ���ð� �ٸ� �� �����Ƿ�, ���� PATH ����(��: `set_user_path.bat`)�� ���ÿ��� �����ؾ� �մϴ�.

���̼���
- �� ������Ʈ�� MIT ���̼����� �����˴ϴ�(���� `LICENSE` ����).

�ǵ�� / �⿩
- ��� �� �������̳� �߰� ���(��: �ӽ� ���ϸ� �浹 ����, `--exist-only` �ɼ�, �� ������ ����ȭ)�� �ʿ��ϸ� �̽��� PR�� �����ּ���.

---
English summary (short)
Pathloader provides simple scripts to manage the user PATH on Windows. Edit `scripts/list.txt`, run the checker, and use the batch script to add missing tool paths. See the README for additional notes about usage, safety and suggestions for enhancements.
