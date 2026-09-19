# OS boundary functions are isolated so tests can replace them without a production bypass flag.
bm_os() { /usr/bin/uname -s; }
bm_arch() { /usr/bin/uname -m; }
bm_os_version() { /usr/bin/sw_vers -productVersion; }
bm_uid() { /usr/bin/id -u; }
bm_arm_hardware() { /usr/sbin/sysctl -in hw.optional.arm64 2>/dev/null || printf '0'; }
bm_translated() { /usr/sbin/sysctl -in sysctl.proc_translated 2>/dev/null || printf '0'; }
bm_clt_ready() {
  local dir
  dir=$(/usr/bin/xcode-select -p 2>/dev/null) || return 1
  [ -d "$dir" ] && /usr/bin/xcrun --find clang >/dev/null 2>&1
}
bm_is_executable() { [ -x "$1" ] && [ ! -d "$1" ]; }
bm_brew() {
  # No persistent Homebrew configuration is changed. Vendor caches may be written by Homebrew.
  (
    unset HOMEBREW_CASK_OPTS HOMEBREW_BOTTLE_DOMAIN HOMEBREW_API_DOMAIN
    unset HOMEBREW_BREW_GIT_REMOTE HOMEBREW_CORE_GIT_REMOTE
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_UPGRADE=1
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_ASK=1
    "$BM_BREW" "$@"
  )
}
bm_find_command() {
  # Respect an existing PATH tool first, including incompatible installations.
  local path
  path=$(command -v "$1" 2>/dev/null) || path=
  if [ -n "$path" ]; then case "$path" in /*) ;; *) return 3 ;; esac; printf '%s' "$path"; return 0; fi
  case "$1" in
    node) path="$BM_PREFIX/opt/node@24/bin/node" ;;
    *) path="$BM_PREFIX/bin/$1" ;;
  esac
  bm_is_executable "$path" || return 2
  printf '%s' "$path"
}
bm_version() {
  case "${1##*/}" in 7zz) "$1" -h 2>&1 ;; *) "$1" --version 2>&1 ;; esac
}
bm_on_path() { command -v "$1" >/dev/null 2>&1; }
bm_node_tools() { [ -x "${1%/*}/npm" ] && [ -x "${1%/*}/npx" ]; }
bm_find_java() {
  local home text
  home=$(/usr/libexec/java_home -v "$1" 2>/dev/null) || return 2
  [ -x "$home/bin/java" ] || return 3
  text=$("$home/bin/java" -version 2>&1) || return 3
  [[ "$text" =~ version[[:space:]]\"([0-9]+)\. ]] || return 3
  [ "${BASH_REMATCH[1]}" = "$1" ] || return 2
}
bm_find_app() {
  local base path ident exe
  for base in /Applications "$HOME/Applications"; do
    path="$base/$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
      [ -f "$path/Contents/Info.plist" ] || return 3
      ident=$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$path/Contents/Info.plist" 2>/dev/null) || return 3
      exe=$(/usr/bin/plutil -extract CFBundleExecutable raw -o - "$path/Contents/Info.plist" 2>/dev/null) || return 3
      case "$exe" in ''|*/*|*..*) return 3 ;; esac
      [ -n "$ident" ] && [ -x "$path/Contents/MacOS/$exe" ] || return 3
      printf '%s' "$path"; return 0
    fi
  done
  return 2
}
bm_find_code() {
  local path
  path=$(bm_find_app 'Visual Studio Code.app') || return $?
  bm_is_executable "$path/Contents/Resources/app/bin/code" || return 3
  printf '%s' "$path/Contents/Resources/app/bin/code"
}
bm_code() { "$BM_CODE" "$@"; }
bm_xcode_ready() {
  local dir
  dir=$(/usr/bin/xcode-select -p 2>/dev/null) || return 1
  case "$dir" in *.app/Contents/Developer) ;; *) return 1 ;; esac
  [ -x "$dir/usr/bin/xcodebuild" ] &&
    /usr/bin/xcrun --find simctl >/dev/null 2>&1 &&
    /usr/bin/xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1
}
bm_sdk_ready() {
  local sdk="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
  # Do not start adb, download an SDK, accept licenses or change a device.
  [ -x "$sdk/platform-tools/adb" ] && [ -d "$sdk/platforms" ] && [ -d "$sdk/build-tools" ]
}
bm_lock_acquire() {
  # Refuse symlinks; never recursively delete a user path or automatically remove stale locks.
  local base="$HOME/.mitchell-bootstrap"
  [ ! -L "$base" ] || return 1
  if [ -e "$base" ]; then
    [ -d "$base" ] && [ -O "$base" ] || return 1
  else
    (umask 077; mkdir "$base") || return 1
  fi
  BM_LOCK="$base/install.lock"
  (umask 077; mkdir "$BM_LOCK") 2>/dev/null || return 1
  BM_HAVE_LOCK=1
}
bm_lock_release() {
  if [ "${BM_HAVE_LOCK:-0}" = 1 ]; then
    rmdir "$BM_LOCK" 2>/dev/null || return 1
    BM_HAVE_LOCK=0
  fi
}
