# macOS 공식 자료 확인

확인일 2026-09-19. 아래는 구현 API/패키지 식별자 확인이며 실제 설치 검증이 아니다. web cache의 서로 다른 patch 버전을 최신 설치 보장으로 인용하지 않고 ID/major 정책만 채택했다.

| 근거 | URL | 적용 |
|---|---|---|
| Homebrew Installation | https://docs.brew.sh/Installation | macOS14+, CLT, arm64/Intel stock prefix, 최초 수동 설치 |
| brew manpage | https://docs.brew.sh/Manpage | list/install, no-auto-update/cleanup/upgrade, cask require-sha; 의존성 변경 가능 |
| Apple CLT | https://developer.apple.com/documentation/xcode/installing-the-command-line-tools | xcode-select 설치·사용자 라이선스, full Xcode와 구분 |
| VS Code macOS | https://code.visualstudio.com/docs/setup/mac | App 설치, 사용자 PATH 등록 |
| VS Code CLI | https://code.visualstudio.com/docs/configure/command-line | list/install-extension, force 사용 안 함 |
| 공식 runner 표 | https://docs.github.com/en/actions/reference/runners/github-hosted-runners | macos-14 arm64, macos-15-intel; VM은 사용자 Mac 실기 수락 아님 |

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
