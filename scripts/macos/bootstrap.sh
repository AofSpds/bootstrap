#!/bin/bash
# Bash 3.2 compatible: no associative arrays, eval, global installs via npm, or shell-profile writes.
BM_ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd) || exit 1
. "$BM_ROOT/config/macos/catalogue.sh"
. "$BM_ROOT/scripts/macos/platform.sh"

bm_emit() {
  # Only our fixed IDs, states and reason codes enter output. Raw vendor output is not logged.
  printf '%s\t%s\t%s\n' "$1" "$2" "$3"
  case "$2" in FAILED) BM_RESULT=1 ;; ACTION_REQUIRED) [ "$BM_RESULT" = 1 ] || BM_RESULT=2 ;; esac
}
bm_usage() {
  cat <<'HELP'
Bootstrap macOS v0.2 (author candidate; real Mac installation not yet accepted)
/bin/bash bootstrap.command --mode Plan|Install|Verify --profile Core|Mobile
  --ai None|Codex|Claude|Both
  --optional Python,PowerShell,SevenZip,Java21,Docker,DBeaver
  --accept                    approve the selected Install operation
  --allow-unverified-intel     explicitly allow the unverified Intel install path
Install: macOS 15+; macOS 14 supports diagnostic Plan/Verify only.
No arguments: Plan; in Terminal, bootstrap.command offers a menu.
Exit 0: requested checks/plan complete, 1: failed, 2: user action needed.
HELP
}
bm_add() { case " $BM_SELECTED " in *" $1 "*) ;; *) BM_SELECTED="$BM_SELECTED $1" ;; esac; }
bm_parse() {
  BM_MODE=Plan; BM_PROFILE=Core; BM_AI=None; BM_ACCEPT=0; BM_INTEL=0; BM_HELP=0
  BM_SELECTED='Git GitHubDesktop GitHubCLI VSCode Node'; local options='' key val
  while [ "$#" -gt 0 ]; do
    key=$1; shift
    case "$key" in
      --help|-h) BM_HELP=1 ;;
      --accept) BM_ACCEPT=1 ;;
      --allow-unverified-intel) BM_INTEL=1 ;;
      --mode|--profile|--ai|--optional)
        [ "$#" -gt 0 ] || return 1; val=$1; shift
        case "$key" in --mode) BM_MODE=$val ;; --profile) BM_PROFILE=$val ;; --ai) BM_AI=$val ;; --optional) options=$val ;; esac ;;
      *) return 1 ;;
    esac
  done
  case "$BM_MODE" in Plan|Install|Verify) ;; *) return 1 ;; esac
  case "$BM_PROFILE" in Core) ;; Mobile) bm_add Java17; bm_add CocoaPods; bm_add AndroidStudio ;; *) return 1 ;; esac
  case "$BM_AI" in None|Codex|Claude|Both) ;; *) return 1 ;; esac
  case "$options" in ,*|*,|*,,*) return 1 ;; esac
  local oldifs=$IFS; IFS=,
  for val in $options; do
    case "$val" in Python|PowerShell|SevenZip|Java21|Docker|DBeaver) bm_add "$val" ;; *) IFS=$oldifs; return 1 ;; esac
  done
  IFS=$oldifs
}
bm_preflight() {
  local os arch version major arm translated prefix uid
  os=$(bm_os) || { bm_emit Platform FAILED OS_QUERY_FAILED; return 1; }
  [ "$os" = Darwin ] || { bm_emit Platform ACTION_REQUIRED MACOS_ONLY; return 1; }
  uid=$(bm_uid) || { bm_emit Platform FAILED UID_QUERY_FAILED; return 1; }
  case "$uid" in ''|*[!0-9]*) bm_emit Platform FAILED UID_QUERY_FAILED; return 1 ;; esac
  [ "$uid" != 0 ] || { bm_emit Platform ACTION_REQUIRED RUN_AS_NORMAL_USER; return 1; }
  case "${HOME:-}" in /*) ;; *) bm_emit Platform ACTION_REQUIRED INVALID_HOME; return 1 ;; esac
  [ -d "$HOME" ] || { bm_emit Platform ACTION_REQUIRED INVALID_HOME; return 1; }
  version=$(bm_os_version) || { bm_emit Platform FAILED VERSION_QUERY_FAILED; return 1; }
  case "$version" in ''|*[!0-9.]*) bm_emit Platform ACTION_REQUIRED UNKNOWN_MACOS_VERSION; return 1 ;; esac
  major=${version%%.*}
  [ -n "$major" ] && [ "$major" -ge 14 ] 2>/dev/null || { bm_emit Platform ACTION_REQUIRED MACOS_14_REQUIRED; return 1; }
  # Homebrew's 2026-09 support policy supersedes the original macOS 14 install floor.
  # Diagnose old installations, but never start package or extension writes on macOS 14.
  if [ "$major" -lt 15 ]; then
    if [ "$BM_MODE" = Install ]; then
      bm_emit Platform ACTION_REQUIRED MACOS_15_REQUIRED_FOR_INSTALL; return 1
    fi
    bm_emit Platform ACTION_REQUIRED MACOS_14_DIAGNOSTIC_ONLY
  fi
  arch=$(bm_arch); arm=$(bm_arm_hardware); translated=$(bm_translated)
  if [ "$translated" = 1 ] || { [ "$arm" = 1 ] && [ "$arch" = x86_64 ]; }; then
    bm_emit Platform ACTION_REQUIRED REOPEN_NATIVE_TERMINAL; return 1
  fi
  case "$arch" in
    arm64) BM_PREFIX=/opt/homebrew ;;
    x86_64)
      BM_PREFIX=/usr/local; bm_emit Platform DETECTED INTEL_DEVICE_UNVERIFIED
      if [ "$BM_MODE" = Install ] && [ "$BM_INTEL" != 1 ]; then bm_emit Platform ACTION_REQUIRED INTEL_OPT_IN_REQUIRED; return 1; fi ;;
    *) bm_emit Platform ACTION_REQUIRED UNSUPPORTED_ARCH; return 1 ;;
  esac
  bm_clt_ready || { bm_emit CLT ACTION_REQUIRED INSTALL_CLT_FROM_APPLE_THEN_RERUN; return 1; }
  BM_BREW="$BM_PREFIX/bin/brew"
  bm_is_executable "$BM_BREW" || { bm_emit Homebrew ACTION_REQUIRED INSTALL_OFFICIAL_HOMEBREW_THEN_RERUN; return 1; }
  prefix=$(bm_brew --prefix 2>/dev/null) || { bm_emit Homebrew FAILED BREW_PREFIX_QUERY_FAILED; return 1; }
  [ "$prefix" = "$BM_PREFIX" ] || { bm_emit Homebrew ACTION_REQUIRED NONSTANDARD_BREW_PREFIX; return 1; }
  bm_inventory || return 1
  bm_emit Platform READY MACOS_PREREQUISITES_DETECTED
}
bm_inventory() {
  BM_INVENTORY_OK=0
  BM_FORMULAE=$(bm_brew list --formula -1 2>/dev/null) || { bm_emit Homebrew FAILED FORMULA_INVENTORY_FAILED; return 1; }
  BM_CASKS=$(bm_brew list --cask -1 2>/dev/null) || { bm_emit Homebrew FAILED CASK_INVENTORY_FAILED; return 1; }
  local token names
  for names in "$BM_FORMULAE" "$BM_CASKS"; do
    while IFS= read -r token; do
      [ -n "$token" ] || continue
      case "$token" in *[!a-zA-Z0-9+@._/-]*) bm_emit Homebrew FAILED INVALID_INVENTORY; return 1 ;; esac
    done <<NAMES
$names
NAMES
  done
  BM_INVENTORY_OK=1
}
bm_has_receipt() {
  local names=$BM_FORMULAE name
  [ "$BM_KIND" != cask ] || names=$BM_CASKS
  while IFS= read -r name; do [ "$name" != "$BM_TOKEN" ] || return 0; done <<RECEIPTS
$names
RECEIPTS
  return 1
}
bm_probe() {
  # 0 detected, 2 proven missing, 3 broken/incompatible, 4 PATH help, 5 lookup error.
  local path text major minor
  if [ -n "$BM_APP" ]; then bm_find_app "$BM_APP" >/dev/null; return $?; fi
  case "$BM_COMMAND" in java17) bm_find_java 17; return $? ;; java21) bm_find_java 21; return $? ;; esac
  path=$(bm_find_command "$BM_COMMAND") || return $?
  text=$(bm_version "$path") || return 3
  if [ "$BM_VERSION" = node ]; then
    [[ "$text" =~ ^v(22|24)\.([0-9]+)\.([0-9]+)$ ]] || return 3
    major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}
    if [ "$major" = 22 ] && [ "$minor" -lt 16 ]; then return 3; fi
    bm_node_tools "$path" || return 3
    # Do not overwrite a different PATH tool. The caller's next shell needs keg-only Node on PATH.
    bm_on_path node || return 4
  fi
  [ -n "$text" ] || return 3
  return 0
}
bm_process() {
  local id=$1 probe rc
  [ "${BM_INVENTORY_OK:-0}" = 1 ] || { bm_emit "$id" FAILED INVENTORY_UNAVAILABLE; return; }
  bm_package "$id" || { bm_emit Catalogue FAILED INVALID_PACKAGE_ID; return; }
  bm_probe >/dev/null 2>&1; probe=$?
  case "$probe" in
    0) bm_emit "$id" DETECTED EXISTING_PRESERVED; return ;;
    3) bm_emit "$id" ACTION_REQUIRED EXISTING_TOOL_NEEDS_REPAIR; return ;;
    4) bm_emit "$id" ACTION_REQUIRED NODE_PATH_SETUP; return ;;
    5) bm_emit "$id" FAILED APP_PATH_QUERY_FAILED; return ;;
    2) ;;
    *) bm_emit "$id" FAILED DETECTION_FAILED; return ;;
  esac
  if bm_has_receipt; then bm_emit "$id" ACTION_REQUIRED INSTALLED_RECEIPT_BUT_TOOL_MISSING; return; fi
  case "$BM_MODE" in
    Plan) bm_emit "$id" PLANNED MISSING; return ;;
    Verify) bm_emit "$id" ACTION_REQUIRED MISSING; return ;;
  esac
  bm_emit "$id" INSTALLING SELECTED_PACKAGE_AND_DEPENDENCIES
  # Fixed official tap names; checksums/quarantine are never disabled. No sudo in this script.
  if [ "$BM_KIND" = cask ]; then
    bm_brew install --cask --require-sha "homebrew/cask/$BM_TOKEN" </dev/null >/dev/null 2>&1; rc=$?
  else
    bm_brew install --formula "homebrew/core/$BM_TOKEN" </dev/null >/dev/null 2>&1; rc=$?
  fi
  if [ "$rc" -ne 0 ]; then bm_emit "$id" FAILED "INSTALL_EXIT_$rc"; return; fi
  # Invocation success is not enough: require a new receipt and successful detection.
  bm_inventory || return
  if ! bm_has_receipt; then bm_emit "$id" FAILED INSTALL_RECEIPT_MISSING; return; fi
  bm_probe >/dev/null 2>&1; probe=$?
  case "$probe" in
    0) bm_emit "$id" INSTALLED DETECTION_PASSED ;;
    4) bm_emit "$id" ACTION_REQUIRED NODE_PATH_SETUP ;;
    *) bm_emit "$id" FAILED POST_INSTALL_DETECTION_FAILED ;;
  esac
}
bm_extensions() {
  [ "$BM_AI" != None ] || return 0
  local extensions fresh id found line rc
  BM_CODE=$(bm_find_code 2>/dev/null) || { bm_emit AI ACTION_REQUIRED VSCODE_CLI_REQUIRED; return; }
  extensions=$(bm_code --list-extensions 2>/dev/null) || { bm_emit AI FAILED EXTENSION_QUERY_FAILED; return; }
  local selected=''
  case "$BM_AI" in Codex) selected=openai.chatgpt ;; Claude) selected=anthropic.claude-code ;; Both) selected='openai.chatgpt anthropic.claude-code' ;; esac
  for id in $selected; do
    found=0
    while IFS= read -r line; do [ "$line" != "$id" ] || found=1; done <<EXTENSIONS
$extensions
EXTENSIONS
    if [ "$found" = 1 ]; then bm_emit "$id" DETECTED EXISTING_PRESERVED; continue; fi
    case "$BM_MODE" in
      Plan) bm_emit "$id" PLANNED MISSING ;;
      Verify) bm_emit "$id" ACTION_REQUIRED MISSING ;;
      Install)
        bm_code --install-extension "$id" </dev/null >/dev/null 2>&1; rc=$?
        # A write (including a partially failed one) invalidates the old snapshot.
        # Never decide that the next extension is absent from failed/partial output.
        if [ "$rc" -ne 0 ]; then bm_emit "$id" FAILED "EXTENSION_EXIT_$rc"; fi
        fresh=$(bm_code --list-extensions 2>/dev/null) || {
          bm_emit "$id" FAILED EXTENSION_QUERY_FAILED
          bm_emit AI ACTION_REQUIRED EXTENSION_REFRESH_REQUIRED
          return 1
        }
        extensions=$fresh
        [ "$rc" -eq 0 ] || continue
        found=0
        while IFS= read -r line; do [ "$line" != "$id" ] || found=1; done <<EXTENSIONS
$extensions
EXTENSIONS
        if [ "$found" = 1 ]; then bm_emit "$id" INSTALLED LOGIN_MANUALLY; else bm_emit "$id" FAILED EXTENSION_NOT_DETECTED; fi ;;
    esac
  done
}
bm_mobile() {
  [ "$BM_PROFILE" = Mobile ] || return 0
  if bm_xcode_ready; then bm_emit Xcode DETECTED TOOLS_ONLY_NOT_BUILD_ACCEPTANCE
  else bm_emit Xcode ACTION_REQUIRED INSTALL_FULL_XCODE_SELECT_AND_FIRST_LAUNCH_MANUALLY; fi
  if bm_sdk_ready; then bm_emit AndroidSDK DETECTED FILES_ONLY_NOT_BUILD_ACCEPTANCE
  else bm_emit AndroidSDK ACTION_REQUIRED COMPLETE_ANDROID_STUDIO_SDK_SETUP_MANUALLY; fi
}
bm_cleanup() { bm_lock_release || :; }
bm_main() {
  BM_RESULT=0; BM_HAVE_LOCK=0
  if ! bm_parse "$@"; then bm_emit Arguments ACTION_REQUIRED INVALID_ARGUMENT; bm_usage; return 2; fi
  if [ "$BM_HELP" = 1 ]; then bm_usage; return 0; fi
  bm_preflight || return "$BM_RESULT"
  local id answer
  if [ "$BM_MODE" = Install ]; then
    printf '선택 목록: %s | AI=%s\n' "$BM_SELECTED" "$BM_AI"
    printf 'Homebrew 의존성 설치·갱신 및 선택한 앱 약관을 확인하세요. 기존 대상은 덮어쓰지 않습니다.\n'
    printf '관리자 확인이 필요하면 Homebrew가 사용자에게 요청할 수 있습니다. 계정 로그인은 직접 합니다.\n'
    if [ "$BM_ACCEPT" != 1 ]; then
      if [ ! -t 0 ]; then bm_emit Consent ACTION_REQUIRED ACCEPT_REQUIRED; return 2; fi
      printf '위 범위의 설치를 승인하면 INSTALL 입력: '
      IFS= read -r answer || answer=''
      [ "$answer" = INSTALL ] || { bm_emit Consent ACTION_REQUIRED DECLINED; return 2; }
    fi
    bm_lock_acquire || { bm_emit Lock ACTION_REQUIRED INSTALL_LOCKED_OR_UNSAFE; return 2; }
    trap bm_cleanup EXIT
    trap 'bm_cleanup; exit 130' INT
    trap 'bm_cleanup; exit 143' TERM
    # Another Bootstrap may have finished while consent was displayed.
    bm_inventory || { bm_cleanup; return "$BM_RESULT"; }
  fi
  for id in $BM_SELECTED; do bm_process "$id"; done
  bm_extensions
  bm_mobile
  if [ "$BM_MODE" = Install ]; then
    bm_lock_release || bm_emit Lock ACTION_REQUIRED LOCK_RELEASE_FAILED
    trap - EXIT INT TERM
  fi
  printf '결과: exit=%s (0=요청 완료, 1=실패, 2=사용자 조치 필요). 설치본 출시 판정이 아닙니다.\n' "$BM_RESULT"
  return "$BM_RESULT"
}
if [ "${BASH_SOURCE[0]}" = "$0" ]; then bm_main "$@"; exit $?; fi
