# macOS 공식 자료 확인

최초 확인일 2026-09-19 / 지원 정책 재확인 2026-09-20. 아래는 구현 API/패키지 식별자 확인이며 실제 설치 검증이 아니다. web cache의 서로 다른 patch 버전을 최신 설치 보장으로 인용하지 않고 ID/major 정책만 채택했다.

| 근거 | URL | 적용 |
|---|---|---|
| Homebrew Installation | https://docs.brew.sh/Installation | macOS15+ Apple Silicon 설치선, Intel Tier3, CLT·stock prefix·최초 수동 설치 |
| brew manpage | https://docs.brew.sh/Manpage | list/install, no-auto-update/cleanup/upgrade, cask require-sha; 의존성 변경 가능 |
| Apple CLT | https://developer.apple.com/documentation/xcode/installing-the-command-line-tools | xcode-select 설치·사용자 라이선스, full Xcode와 구분 |
| VS Code macOS | https://code.visualstudio.com/docs/setup/mac | App 설치, 사용자 PATH 등록 |
| VS Code CLI | https://code.visualstudio.com/docs/configure/command-line | list/install-extension, force 사용 안 함 |
| 공식 runner 표 | https://docs.github.com/en/actions/reference/runners/github-hosted-runners | macos-15 arm64, macos-15-intel; VM은 사용자 Mac 실기 수락 아님 |

고정 설치 ID의 공식 목록:

- https://formulae.brew.sh/formula/git
- https://formulae.brew.sh/formula/gh
- https://formulae.brew.sh/formula/node@24
- https://formulae.brew.sh/cask/github
- https://formulae.brew.sh/cask/visual-studio-code
- https://formulae.brew.sh/formula/python@3.13
- https://formulae.brew.sh/formula/powershell (formula로 확인; 오래된 cask 가정을 사용하지 않음)
- https://formulae.brew.sh/formula/sevenzip (7zip alias 대신 canonical ID)
- https://formulae.brew.sh/cask/temurin@17
- https://formulae.brew.sh/cask/temurin@21
- https://formulae.brew.sh/formula/cocoapods
- https://formulae.brew.sh/cask/android-studio
- https://formulae.brew.sh/cask/docker-desktop
- https://formulae.brew.sh/cask/dbeaver-community

Codex/Claude의 extension IDs는 Windows 기준선 config/scripts와 기존 승인·검증 범위에서 재사용한다. 가입·요금·계정 기능을 새로 검증하거나 추가하지 않았다. Homebrew·Xcode·각 앱의 실제 설치 및 라이선스는 사용자 수락 단계에서 현행 조건을 다시 확인한다.

## 지원 정책 원문 재확인 / 2026-09-20

웹 검색·열람 캐시에 macOS14/Intel 지원이라는 이전 표기가 남아 있어 GitHub connector로 Homebrew/brew의 docs/Installation.md를 직접 읽었다. 원문 last_review_date는2026-09-17, blob은 d7b95f04a6cd1cbe473a0ab2462e587f68348530이며 Apple Silicon/macOS15+와 Intel Tier3를 명시한다. https://docs.brew.sh/Support-Tiers 의2026년9월 전환도 참고했다. 원 v0.2의14+ 설치선은 현재 문서의15+ 설치선으로 대체하며 기존14 환경에는 진단만 허용한다.

이 변경은 Bootstrap 설치 정책의 보수적 갱신이며 OS를 자동 업그레이드하거나 모든15+ 하드웨어/패키지 수락을 보장하지 않는다. 기존78a919e 후보의 macos14 CI 성공은 해당 소스의 Bash·진단 시험 기록으로 보존한다. 새 후보의 macos15 CI 결과와 구분한다.
