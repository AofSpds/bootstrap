# macOS v0.2 시험 경계

코드/명령 경계 fixture, macOS runner의 Bash 실행, 실제 신규 Mac 설치 수락은 서로 다른 증거다.

## 작성자 검사

- tests/macos/test_bootstrap.py: 제품 Bash 엔진을 직접 실행하고 OS/Homebrew/VS Code 경계만 가짜 함수로 대체. 격리 HOME에서 사용자 dotfiles 보존, lock은 실제 파일 I/O.
- tests/macos/check_windows_baseline.py: Git blob 기준 Windows 코드·구성·시험·기존 workflow 보존. README만 macOS 안내 추가.
- macOS workflow: stock `/bin/bash` syntax+fixtures, 실제 runner에서 read-only Verify. 실제 패키지 설치·로그인·권한 승인 없음.
- native probe는 CLI version 또는 App/SDK 파일 구조 탐지다. Xcode/Android build·Simulator boot·로그인 완료를 뜻하지 않는다.

최종 exact head/tree와 실행 job/결과는 AofSpds/mitchell의 BOOTSTRAP_MACOS_* 완료보고·Manifest가 소유한다. 본 파일에 미래 CI PASS를 예상해 넣지 않는다. 기존 Windows B001/B002 PASS는 macOS IVA에 적용하지 않는다.

## 별도 수락 목록 — 모두 NOT_RUN

| 시나리오 | 상태 |
|---|---|
| 깨끗한 Apple Silicon macOS14+에서 ZIP/.command·권한·보안 경고·메뉴 | NOT_RUN |
| CLT 없는 Mac, Homebrew 없는 Mac, 최초 수동 설치 후 재개 | NOT_RUN |
| 실제 brew Core 및 Optional/Mobile 설치, 실패·부분성공·재실행 | NOT_RUN |
| nvm/asdf/volta·기존 여러 Node·앱·Homebrew 변형 보존 | NOT_RUN |
| 공간 부족·오프라인·다운로드/인증서·관리자 승인 거부·중단 | NOT_RUN |
| 실제 Xcode license/first-launch/SDK/Simulator build | NOT_RUN |
| 실제 Android SDK/Java·emulator/adb·휴대폰 연결 | NOT_RUN |
| Codex/Claude/GitHub 로그인과 기존 구독 접근 | NOT_RUN |
| Intel Mac 전체 수락 | NOT_RUN / UNVERIFIED |
| 별도 IVA / v0.2 병합 / 릴리스 | NOT_RUN / NOT_DONE / NOT_DONE |

실기에는 사용자의 명시적 설치 승인과 테스트 Mac 참여가 필요하다. 실행 로그는 개인 경로·토큰이 있을 수 있으므로 원문을 Public Git에 올리지 않는다. 검증자가 없다는 이유로 작성자를 IVA로 바꾸지 않는다.
