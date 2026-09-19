#!/bin/bash
# Isolated command-boundary fixture; NEVER invokes real brew, code, CLT or installers.
. "$1/scripts/macos/bootstrap.sh"; shift
fixture_has() { grep -Fqx -- "$1" "$FIXTURE/tools"; }
fixture_receipt() { grep -Fqx -- "$1" "$FIXTURE/receipts"; }
bm_os() { printf '%s' "${F_OS:-Darwin}"; }
bm_arch() { printf '%s' "${F_ARCH:-arm64}"; }
bm_os_version() { printf '%s' "${F_VERSION:-14.7}"; }
bm_uid() { printf '%s' "${F_UID:-501}"; }
bm_arm_hardware() { printf '%s' "${F_ARM:-1}"; }
bm_translated() { printf '%s' "${F_TRANSLATED:-0}"; }
bm_clt_ready() { [ "${F_CLT:-1}" = 1 ]; }
bm_is_executable() { [ "${F_BREW:-1}" = 1 ]; }
bm_brew() {
  printf '%s\n' "$*" >> "$FIXTURE/calls"
  case "$1" in
    --prefix) printf '%s' "${F_PREFIX:-$BM_PREFIX}" ;;
    list)
      if [ "${F_INVENTORY:-ok}" = fail ]; then printf 'token-secret /Users/private' >&2; return 77; fi
      if [ "${F_AFTER_INVENTORY_FAIL:-0}" = 1 ] && [ -f "$FIXTURE/installed" ]; then return 78; fi
      while IFS= read -r token; do
        case "$token" in github|visual-studio-code|temurin@*|docker-desktop|dbeaver-community|android-studio) kind=--cask ;; *) kind=--formula ;; esac
        [ "$kind" != "$2" ] || printf '%s\n' "$token"
      done < "$FIXTURE/receipts" ;;
    install)
      local token=${!#}; token=${token##*/}
      if [ "$token" = "${F_INSTALL_FAIL:-never}" ]; then printf 'password=secret /Users/private' >&2; return 42; fi
      touch "$FIXTURE/installed"
      [ "${F_NO_RECEIPT:-never}" = "$token" ] || printf '%s\n' "$token" >> "$FIXTURE/receipts"
      [ "${F_NO_TOOL:-never}" = "$token" ] || printf '%s\n' "$token" >> "$FIXTURE/tools" ;;
    *) echo 'UNEXPECTED_BREW_COMMAND' >&2; return 99 ;;
  esac
}
bm_find_command() {
  [ "${F_BROKEN:-never}" != "$BM_TOKEN" ] || return 3
  fixture_has "$BM_TOKEN" || return 2
  printf '%s' "$FIXTURE/bin/$BM_COMMAND"
}
bm_version() {
  [ "${F_VERSION_FAIL:-never}" != "$BM_TOKEN" ] || return 1
  if [ "$BM_VERSION" = node ]; then printf '%s' "${F_NODE:-v24.1.0}"; else printf 'fixture 1.0'; fi
}
bm_on_path() { [ "${F_NODE_PATH:-1}" = 1 ]; }
bm_node_tools() { [ "${F_NPM:-1}" = 1 ]; }
bm_find_java() { fixture_has "temurin@$1" || return 2; }
bm_find_app() {
  local token=$BM_TOKEN
  [ "${F_BROKEN:-never}" != "$token" ] || return 3
  fixture_has "$token" || return 2
  printf '%s' "$FIXTURE/Applications/$1"
}
bm_find_code() { fixture_has visual-studio-code || return 2; printf '%s' "$FIXTURE/code"; }
bm_code() {
  printf 'code %s\n' "$*" >> "$FIXTURE/calls"
  case "$1" in
    --list-extensions) [ "${F_EXT_QUERY_FAIL:-0}" != 1 ] || return 7; cat "$FIXTURE/extensions" ;;
    --install-extension)
      [ "${F_EXT_FAIL:-0}" != 1 ] || return 43
      [ "${F_EXT_NO_DETECT:-0}" = 1 ] || printf '%s\n' "$2" >> "$FIXTURE/extensions" ;;
    *) return 99 ;;
  esac
}
bm_xcode_ready() { [ "${F_XCODE:-0}" = 1 ]; }
bm_sdk_ready() { [ "${F_SDK:-0}" = 1 ]; }
bm_main "$@"
exit $?
