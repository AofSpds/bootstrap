# Mac 첫 실행

Apple Silicon·macOS 15 이상을 기본 설치 대상으로 하는 개발환경 Bootstrap 후보입니다. macOS 14에서는 설치 없이 Plan/Verify 진단만 가능하며 조치 필요(exit2)로 표시합니다. **iPhone/iPad에 설치하는 앱이 아닙니다.** 실제 사용자 Mac 수락과 독립 IVA는 아직 별도 단계입니다.

## 처음 한 번

저장소 ZIP을 전부 압축 해제합니다. `bootstrap.command`를 열면 계획/설치/검사와 Core/Mobile, AI 확장을 선택할 수 있습니다. 기본은 설치하지 않는 Plan입니다.

실행권한이 없다면 다운로드 출처와 코드를 확인한 뒤 Terminal에서 해당 폴더로 이동해 아래처럼 직접 실행할 수 있습니다. OS 보안 경고는 시스템의 보안 절차에 따라 판단하며 `xattr -d`, Gatekeeper 해제, Rosetta 강제 설치를 사용하지 않습니다.

```sh
/bin/bash ./bootstrap.command --mode Plan
```

CLT가 없으면 먼저 Apple의 안내에 따라 `xcode-select --install`을 직접 실행해 설치·라이선스를 확인합니다. Homebrew가 없으면 `https://brew.sh`의 공식 설치 방법을 직접 검토해 준비합니다. Bootstrap은 원격 설치 스크립트를 다운로드·실행하거나 비밀번호를 받지 않습니다. Apple Silicon 표준 경로는 `/opt/homebrew`, Intel은 `/usr/local`입니다.

```sh
# 설치·설정 변경 명령 없이 현재 상태 검사
/bin/bash ./bootstrap.command --mode Plan
# 목록과 동의 문구 확인 후 INSTALL 입력
/bin/bash ./bootstrap.command --mode Install --profile Core --ai Codex
# 현재 설치 여부만 검사
/bin/bash ./bootstrap.command --mode Verify --profile Core --ai Codex
# 모바일 도구 선택. Xcode·SDK 설정은 별도 수동 단계
/bin/bash ./bootstrap.command --mode Install --profile Mobile --ai None
# 필요한 선택 도구만 추가
/bin/bash ./bootstrap.command --mode Install --optional Python,DBeaver
```

이미 범위·약관을 확인한 자동 호출은 `--accept`를 명시합니다. 승인 없는 비대화 Install은 exit2로 종료합니다. Intel은 Homebrew Tier 3이며 기본 권장 대상이 아닙니다. macOS 15 이상의 Intel 설치 후보는 `--allow-unverified-intel`도 필요하며, 이 플래그는 macOS 14 설치 차단을 해제하거나 실제 Intel 수락 PASS를 뜻하지 않습니다.

## 출력 읽기

| 상태/코드 | 의미와 행동 |
|---|---|
| MACOS_15_REQUIRED_FOR_INSTALL | macOS 14 설치를 거부했습니다. OS 호환성을 확인하고 지원 Mac에서 설치하세요. |
| MACOS_14_DIAGNOSTIC_ONLY | 기존 macOS 14 환경 진단만 수행하며 설치하지 않습니다. |
| PLANNED / MISSING | Plan이 발견한 미설치 항목; 설치된 상태가 아님 |
| DETECTED / EXISTING_PRESERVED | 기존 도구를 발견, 업그레이드 안 함. 앱 실행·로그인 수락은 별도 |
| INSTALLED / DETECTION_PASSED | 호출 후 receipt와 CLI/App 구조 확인. 실제 업무 작동 보증 아님 |
| NODE_PATH_SETUP | Node는 있으나 다음 셸에서 쓸 PATH 설정이 필요 |
| EXISTING_TOOL_NEEDS_REPAIR | 기존 버전 비호환/실행 오류. 그대로 보존; 개발자 확인 |
| INSTALLED_RECEIPT_BUT_TOOL_MISSING | Homebrew 기록과 실제 파일 불일치. 자동 재설치 안 함 |
| INSTALL_EXIT_n / POST_INSTALL_DETECTION_FAILED | 실패 또는 실제 설치 여부 확인 실패. 로컬에서 Homebrew 오류 확인 후 Verify |
| *_INVENTORY_FAILED / INVALID_INVENTORY | 목록 자체가 불확실. 빈 목록으로 간주해 덮어쓰지 않음 |
| INSTALL_LOCKED_OR_UNSAFE | 다른 Bootstrap 또는 중단 lock. 실행 중인지 먼저 확인, 무조건 삭제 금지 |

exit0=선택한 요청 처리, exit1=실패, exit2=사용자 조치 필요. 일부 설치 성공 후 실패할 수 있으며 자동 제거하지 않습니다. `.command`를 다시 실행하면 현재 상태를 다시 탐지합니다. Homebrew가 필요한 의존성을 설치·갱신할 수 있으므로 기존 업무용 Mac은 먼저 테스트 환경에서 확인하세요.

## Node와 VS Code PATH

`node@24`는 keg-only일 수 있습니다. 먼저 `command -v node`와 `node --version`으로 기존 버전을 확인합니다. 기존 nvm/asdf/volta 설정이 있으면 섞지 말고 개발자에게 확인합니다.

새 Apple Silicon Homebrew Node를 사용하기로 결정한 경우 **현재 Terminal 세션에서만** 다음처럼 설정하고 Verify할 수 있습니다. Intel은 `/opt/homebrew` 대신 `/usr/local`입니다.

```sh
export PATH="/opt/homebrew/opt/node@24/bin:/opt/homebrew/bin:$PATH"
node --version
npm --version
/bin/bash ./bootstrap.command --mode Verify
```

영구 `.zprofile/.zshrc`는 자동 수정하지 않습니다. 필요시 내용을 확인한 뒤 사용자가 등록합니다. VS Code의 `code` 명령은 Command Palette에서 `Shell Command: Install 'code' command in PATH`를 선택합니다. Bootstrap AI 설치는 표준 VS Code App 내부 CLI도 찾으므로 전역 링크를 강제로 만들지 않습니다.

## Mobile Profile의 마지막 수동 단계

Xcode는 Mac App Store/Apple의 공식 경로에서 OS 호환 버전을 설치하고 첫 실행을 마칩니다. Developer Directory, 라이선스, iOS SDK·Simulator runtime과 실제 빌드는 직접 확인합니다. Android Studio를 열어 SDK Manager에서 필요한 SDK/build-tools/platform-tools/emulator를 설정합니다. SDK·라이선스는 자동 다운로드하거나 수락하지 않습니다. Temurin17과21을 함께 쓰면 프로젝트별 JAVA_HOME을 직접 정합니다.

GitHub Desktop·선택 AI·Apple 계정은 공식 앱에서 직접 로그인합니다. API 키를 이 저장소나 채팅에 넣지 않습니다. 앱 서명·스토어 등록·배포는 이 Bootstrap 작업과 다릅니다.
