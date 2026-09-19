# Fixed identifiers only; never source a downloaded catalogue.
bm_package() {
  BM_KIND=formula; BM_APP=; BM_COMMAND=; BM_VERSION=any
  case "$1" in
    Git) BM_TOKEN=git; BM_COMMAND=git ;;
    GitHubDesktop) BM_KIND=cask; BM_TOKEN=github; BM_APP='GitHub Desktop.app' ;;
    GitHubCLI) BM_TOKEN=gh; BM_COMMAND=gh ;;
    VSCode) BM_KIND=cask; BM_TOKEN=visual-studio-code; BM_APP='Visual Studio Code.app' ;;
    Node) BM_TOKEN=node@24; BM_COMMAND=node; BM_VERSION=node ;;
    Python) BM_TOKEN=python@3.13; BM_COMMAND=python3.13 ;;
    PowerShell) BM_TOKEN=powershell; BM_COMMAND=pwsh ;;
    SevenZip) BM_TOKEN=sevenzip; BM_COMMAND=7zz ;;
    Java17) BM_KIND=cask; BM_TOKEN=temurin@17; BM_COMMAND=java17 ;;
    Java21) BM_KIND=cask; BM_TOKEN=temurin@21; BM_COMMAND=java21 ;;
    Docker) BM_KIND=cask; BM_TOKEN=docker-desktop; BM_APP='Docker.app' ;;
    DBeaver) BM_KIND=cask; BM_TOKEN=dbeaver-community; BM_APP='DBeaver.app' ;;
    CocoaPods) BM_TOKEN=cocoapods; BM_COMMAND=pod ;;
    AndroidStudio) BM_KIND=cask; BM_TOKEN=android-studio; BM_APP='Android Studio.app' ;;
    *) return 1 ;;
  esac
}
