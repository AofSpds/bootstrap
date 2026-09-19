# Bootstrap macOS v0.2 — 설계·작업계획

ID: BOOTSTRAP-MAC-001 / 2026-09-19 / Writer: MITCHELL
범위: 사용자 macOS 확장 실행 승인. Windows 기준선 병합 후 별도 macOS 후보 구현.
코드 작성·시험·Git PR까지 허용한다. 실제 사용자 Mac 설치·라이선스 대리 수락·계정·키·출시·v0.2 병합은 별도다.

## 1. 목적과 구조

기존 Windows v0.1을 유지하면서 Mac도 개발을 시작할 수 있도록 한다. 초기 계획의 macOS 14 설치선은 2026-09-20 공식 원문 재확인으로 수정한다. 기본 설치선은 macOS 15 이상 native Apple Silicon이다. macOS 14는 Plan/Verify 진단 전용이고 Install은 차단한다. Intel은 Homebrew Tier 3이며 macOS 15 이상에서 명시적 opt-in만 허용하는 미수락 후보다. OS 최소선은 모든 버전/하드웨어의 제품 수락 선언이 아니다.

```text
Windows bootstrap.bat → 기존 PowerShell/WinGet (바이트 보존)
Mac bootstrap.command → Bash 3.2 engine
  → 사용자·OS·CPU·Rosetta 검사
  → CLT / stock-prefix Homebrew 확인
  → 로컬 도구·receipt 탐지
  → Plan 또는 Verify: 상태 출력만
  → Install: 선택 목록·동의 → 단일 실행 lock
      → 부족한 공식 패키지 설치 → receipt와 도구 재탐지
      → AI 확장 선택 설치 → 결과와 수동 후속 안내
```

`.command`는 더블클릭 진입점 후보이며 서명된 macOS 앱/PKG가 아니다. 실행권한·Gatekeeper 및 최초 승인에 따른 차이는 실제 Mac에서 시험한다. Windows 파일을 scripts/windows로 옮기지 않는다. 새 구현은 scripts/macos, config/macos, tests/macos, docs/macos에 국소 추가한다.

## 2. 패키지·프로필

| 분류 | 대상 |
|---|---|
| Core | Git(Apple CLT Git도 재사용), GitHub Desktop, GitHub CLI, VS Code, Node |
| Node | 기존 Node 22.16 이상 22.x 또는 24.x 재사용. 미설치 시 node@24. 다른 major·고장난 도구는 보존하고 조치 필요 |
| Optional | Python 3.13, PowerShell, SevenZip, Temurin21, Docker Desktop, DBeaver Community |
| Mobile | Core + Temurin17, CocoaPods, Android Studio; full Xcode와 iOS SDK/Android SDK 존재 확인 |
| AI | None/Codex/Claude/Both, 기존 승인된 공식 VS Code extension IDs 재사용 |
| 내장·제외 | macOS Terminal·압축 도구는 OS 기본 사용. Windows Terminal 제외. 7-Zip/PowerShell은 선택 |

Mobile은 iPhone/Galaxy 실기 연결·빌드 성공을 자동 보증하지 않는다. Xcode/Simulator runtime 다운로드, SDK Manager, 라이선스, JAVA_HOME, Apple 계정/서명은 사용자가 직접 관리한다. Docker는 앱 존재 확인까지이며 daemon 시작/결제/로그인은 하지 않는다.

Homebrew 식별자를 고정하되 전체 패키지 버전을 lock하지 않는다. upstream 최신 patch/bottle/종속성은 실행 시 달라진다. formula가 삭제되거나 지원조건이 바뀌면 실패로 남기며 임의 대체·강제 업그레이드를 하지 않는다. Sources에 확인 URL과 날짜를 기록한다.

## 3. 경계·안전 정책

- Plan/Verify는 Bootstrap의 패키지 설치·약관수락·영구 설정 변경 명령을 실행하지 않는다. Homebrew/OS/VS Code 검사 도구 자체의 캐시까지 무변경이라고 보장하지 않는다.
- CLT/Homebrew가 없으면 중단·공식 설치 안내. root 실행, Rosetta, 잘못된 Homebrew prefix, inventory 오류는 설치 전에 차단한다. Intel Install은 `--allow-unverified-intel`이 필요하다.
- macOS 기본 Bash로 실행하므로 Python/Node를 Bootstrap 실행의 전제조건으로 삼지 않는다. Python은 시험 하네스에서만 사용한다.
- 기존 도구는 PATH 또는 표준 App 경로로 우선 탐지한다. receipt만 남거나 CLI 오류가 있으면 재설치하지 않는다. 앱 탐지는 설치 구조 확인이지 안전성·서명·실행 수락 검증이 아니다.
- 설치는 누락된 선택 대상만 공식 homebrew/core·homebrew/cask 식별자로 요청한다. 직접 upgrade/reinstall/uninstall/link/cleanup·tap 추가는 하지 않는다. Homebrew가 필요한 의존성을 설치·갱신할 수 있다는 점은 동의 전에 안내한다.
- brew auto update/cleanup/installed-dependent repair는 비활성화한다. SHA 확인·macOS 보안·sandbox를 약화하지 않는다. cask는 `--require-sha`. user/system brew.env 등 로컬 Homebrew 설정 전부를 통제한다고 주장하지 않는다.
- `~/.mitchell-bootstrap/install.lock` mkdir로 Bootstrap 간 직렬화. 강제 종료 후 stale lock은 개발자가 실행 여부 확인 후 처리한다. 외부 brew 세션과의 완전한 transaction은 아니다.
- 실패해도 독립 패키지는 진행한다. inventory 자체가 불확실해지면 이후 패키지 설치는 막는다. 성공 호출만으로 INSTALLED가 되지 않으며 receipt+탐지가 필요하다. 자동 rollback/uninstall은 없다.
- 로그는 fixed ID·상태·이유 코드와 숫자 exit만 표준출력에 표시한다. vendor raw stdout/stderr, 환경, 계정, 개인 경로를 수집·Git 기록하지 않는다. 진단이 필요하면 로컬에서 vendor 명령을 직접 확인한다.
- npm global CLI, Git identity, shell dotfiles, Rosetta, signing, SIP/Gatekeeper/quarantine 변경 없음.

## 4. 작업 단계와 완료 기준

| 단계 | 산출물·판정 |
|---|---|
| M00 | Windows PR#1 expected head 병합, merge tree=IVA tree 확인 |
| M01 | 공식 OS/패키지/API 조건 확인, 본 설계·권한 경계 |
| M02 | .command, Bash 엔진, stock Homebrew adapter, 고정 catalogue |
| M03 | 동의·lock·기존 설치 보존·오류·재실행·AI·Mobile 확인 |
| M04 | Linux 격리 boundary fixtures + macOS Bash3.2 CI + Windows blob 보존 |
| M05 | exact 후보·작성자 완료보고·IVA 입력을 Git에 고정 |
| M06 | 별도 IVA 검증 → 승인된 clean/existing Mac 수락 → 별도 병합·릴리스 |

기존 B/W나 SNS 앱의 PASS는 재사용 범위를 넘겨 확장하지 않는다. 작성자 검사를 IVA로 부르지 않는다. 이 계획은 전체 무정보 검증 루프나 PMO dispatch를 만들지 않는다.
