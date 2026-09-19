# bootstrap

Windows 11 x64와 macOS 개발환경을 준비하는 Bootstrap입니다.

- Windows v0.1: PR #1 병합 완료. IVA-B001/B002 교정 재검증 PASS이며 실제 PC 설치 수락·릴리스는 별도입니다.
- macOS v0.2: **작성자 구현 후보**. 아래 macOS 안내를 사용합니다. Windows의 과거 PASS를 macOS 검증으로 확대하지 않습니다.
- macOS: `bootstrap.command` → [첫 실행](docs/macos/FIRST_RUN.md) · [설계·작업계획](docs/macos/WORK_PLAN_v0.2.md) · [시험 범위](docs/macos/ACCEPTANCE.md).
- Windows: 기존 `bootstrap.bat` / `bootstrap.ps1` 경로와 아래 사용법을 보존합니다.

## 시작

Git이 없어도 저장소 ZIP을 내려받아 **압축을 전부 푼 뒤** `bootstrap.bat`을 실행합니다. 설치할 프로그램과 AI를 고르고 설치·약관 동의를 한 번 확인합니다. 필요한 UAC와 GitHub/AI 로그인은 본인이 수행합니다.

```powershell
# 아무것도 설치하지 않고 계획만 확인
.\bootstrap.ps1 -Mode Plan
# 선택 설치: 기존 호환 프로그램은 건드리지 않음
.\bootstrap.ps1 -Mode Install -Profile Core -AI Codex
# 설치 없이 상태만 검사
.\bootstrap.ps1 -Mode Verify -AI Codex
# 이미 선택·동의를 받은 비대화 실행
.\bootstrap.ps1 -Mode Install -Profile Core -AI None -AcceptAgreements -NonInteractive
```

기본: Git, GitHub Desktop, GitHub CLI, VS Code, Node.js LTS(npm/npx 포함), PowerShell 7, Windows Terminal, 7-Zip.
선택: Python 3.13, Temurin JDK 21, Docker Desktop, DBeaver Community. Docker는 WSL/가상화가 이미 준비된 경우만 설치하며 기능을 자동 활성화하지 않습니다.
AI: `None / Codex / Claude / Both`. 공식 VS Code 확장만 설치하며 계정 로그인·API 키 발급·구독은 하지 않습니다.

`Plan`과 `Verify`는 프로그램 설치·업그레이드·영구 설정 변경을 하지 않습니다. `Install`도 기존 프로그램의 업그레이드·제거, 자동 재부팅, 보안 기능 해제, Git 전역 설정 변경을 하지 않습니다. 구버전/불명확한 설치는 `ACTION_REQUIRED`로 남깁니다.

종료코드: 0=요청 처리 완료, 1=설치/검사 실패, 2=사용자 조치 필요. 로그는 Install에서만 `%LOCALAPPDATA%\MitchellBootstrap\logs`에 정제된 결과를 저장합니다. WinGet 자체 로그는 개인정보가 있을 수 있으니 그대로 공유하지 마세요.

설치 후: GitHub Desktop 로그인 → 자기 앱 저장소 Clone → VS Code로 열기 → 선택한 AI 로그인. 이 저장소 자체는 웹앱이 아닙니다.

[첫 실행](docs/FIRST_RUN.md) · [문제 해결](docs/TROUBLESHOOTING.md) · [시험 범위](docs/TESTED_VERSIONS.md) · [공식 근거](docs/SOURCES.md)
