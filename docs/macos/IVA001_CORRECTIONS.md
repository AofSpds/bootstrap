# Bootstrap macOS — IVA-001 표적 교정

Writer: MITCHELL / Date: 2026-09-20 / Scope: MAC-F001–F003

원 후보 753bc82f63f85722cd76ba78b186bcaf46253677의 IVA FAIL은 보존한다.
원 결과: AofSpds/mitchell@b3a72ee5b4814f516b88308d6d65a4704a839a7c,
docs/execution/BOOTSTRAP_MACOS_IVA_RESULT_001_20260920.md,
blob c0904f3302eb04ae4e4d7e9f6a66d49043b257ab.
작성자 교정은 별도 IVA PASS나 실제 Mac 설치 수락을 의미하지 않는다.

## 교정

| Finding | 변경 | 유지 조건 |
|---|---|---|
| MAC-F001 P2 | 확장 설치 시도 후 반드시 목록을 다시 읽는다. 실패·부분 출력은 폐기하고 후속 확장 처리를 종료한다. 설치 명령이 nonzero인 경우도 새 조회를 요구한다. | 기존 확장 보존, 고정 ID, 설치 실패 숫자, 사용자 재실행 시 새 조회, 수동 로그인 |
| MAC-F002 P2 | -e/-L false를 미설치로 확정하지 않는다. 부모 경로의 부재를 재귀적으로 확인하고, 존재하는 부모에서 탐색·직접 자식 열거가 성공한 뒤에만 absence=2를 반환한다. 조회 불확실은5/APP_PATH_QUERY_FAILED로 설치를 차단한다. 두 App 위치를 모두 확인한다. | 정상 부재·없는 사용자 Applications 허용, 고장난 bundle/symlink는 보존, 권한·보안 설정 변경 없음 |
| MAC-F003 P3 | lock 기반 디렉터리 mkdir 오류도 stderr를 직접 출력하지 않는다. | exit2/INSTALL_LOCKED_OR_UNSAFE, 기존 lock과 symlink 보호, 수동 복구 |

## 파일 탐지의 의미

bm_path_state는 errno를 추측하거나 지역화된 stderr를 파싱하지 않는다.
존재가 확인되면0, 정상적인 부모 조회로 부재가 확인되면2, 불확실하면5다.
find는 parent/. 아래 한 단계만 읽으며 경로를 외부 로그로 출력하지 않는다.
패턴 메타문자는 literal로 escape하고 하위 앱·사용자 파일은 재귀 탐색하지 않는다.
기존 App의 plist와 실행 파일 구조를 검사하는 기존 계약은 유지한다.
건강한 첫 App 위치가 접근 불가 두 번째 위치의 오류를 숨기지 않도록 보수적으로 처리한다.
외부 프로세스가 탐지 이후 파일을 바꾸는 모든 경쟁 조건까지 원자적으로 통제하지는 않는다.

## 재현·시험

`python3 tests/macos/test_iva001_corrections.py`를 비특권 사용자로 실행한다.
표적 35개: 확장9, 앱 탐지20, lock6. Bash engine은 실제 코드다.
OS/brew/code는 합성 경계이며 실제 패키지·확장 설치는 수행하지 않는다.
앱/lock 접근 거부는 격리 실제 파일시스템을 사용한다. Mac에서는 Apple plutil,
Linux에서는 시험용 plistlib field adapter만 사용한다. root 실행은 시험 실패다.
MAC_TEST_PRODUCT_ROOT는 과거 소스 대조를 위한 시험 전용 입력이며 제품은 읽지 않는다.

작성자 수치·CI·새 exact head/tree와 artifact는 MITCHELL 완료보고/Manifest가 소유한다.
Windows18개 기존 blob·Homebrew 지원 정책·catalogue·동의·Mobile 범위는 변경하지 않는다.

## 구현 의미 보조 근거 (2026-09-20 확인)

- VS Code CLI: https://code.visualstudio.com/docs/configure/command-line
  --install-extension은 설치/갱신이므로 실패한 조회를 미설치로 해석하지 않는다.
- Apple find(1) 원문: https://github.com/apple-oss-distributions/shell_cmds/blob/main/find/find.1
  -H, -name, -prune, -print와 오류 종료 의미를 참고했다. 실제 macOS 실행은 CI로 구분한다.

실제 Mac 설치·Finder/Gatekeeper·TCC/ACL·실계정·라이선스·모바일 빌드·릴리스는 NOT_RUN이다.
