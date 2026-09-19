#!/bin/bash
# Finder can run this executable .command. Security prompts remain under user control.
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
if [ "$#" = 0 ] && [ -t 0 ]; then
  printf 'Bootstrap macOS: 1=계획(설치 안 함), 2=설치, 3=검사\n선택 [1]: '
  IFS= read -r choice || choice=''
  case "$choice" in ''|1) mode=Plan ;; 2) mode=Install ;; 3) mode=Verify ;; *) exit 2 ;; esac
  printf '프로필: 1=기본, 2=모바일 개발 도구 [1]: '
  IFS= read -r choice || choice=''
  case "$choice" in ''|1) profile=Core ;; 2) profile=Mobile ;; *) exit 2 ;; esac
  printf 'AI 확장: 0=없음, 1=Codex, 2=Claude, 3=둘 다 [0]: '
  IFS= read -r choice || choice=''
  case "$choice" in ''|0) ai=None ;; 1) ai=Codex ;; 2) ai=Claude ;; 3) ai=Both ;; *) exit 2 ;; esac
  /bin/bash "$ROOT/scripts/macos/bootstrap.sh" --mode "$mode" --profile "$profile" --ai "$ai"
  result=$?
  printf '\n자세한 안내: docs/macos/FIRST_RUN.md. 종료하려면 Enter.'
  IFS= read -r ignored || :
  exit "$result"
fi
exec /bin/bash "$ROOT/scripts/macos/bootstrap.sh" "$@"
