# Official implementation references

Checked 2026-09-15. Official documents are implementation references, not proof of installation on a user's PC.

- WinGet install / no-upgrade / agreements / exit behavior: https://learn.microsoft.com/en-us/windows/package-manager/winget/install
- WinGet package catalogue: https://github.com/microsoft/winget-pkgs/tree/master/manifests
- Node LTS 24.21.0 and Node 22 LTS: https://nodejs.org/en/download
- VS Code CLI: https://code.visualstudio.com/docs/configure/command-line
- Codex IDE: https://developers.openai.com/codex/ide/
- Official Codex extension ID: https://marketplace.visualstudio.com/items?itemName=openai.chatgpt
- Claude Code VS Code: https://code.claude.com/docs/en/vs-code
- Official Claude extension ID: https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code
- Docker Desktop license: https://docs.docker.com/subscription/desktop-license/

The installation command fixes package ID, exact matching and the winget source. Unknown/moved packages fail closed; no substitute package or external installer is downloaded. Plan/Verify do not accept source agreements. Runtime `winget show --id ID --exact --source winget` remains part of real Windows qualification, not a test already performed in this Linux authoring environment.
