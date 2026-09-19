# Bootstrap contributor rules

Read README.md and AofSpds/mitchell/docs/IMPLEMENTATION_PLAN_v1.0.md (B01–B05).
This product installs Windows development tools, not personas or an agent operating system.
Keep PowerShell 5.1-compatible syntax; ASCII scripts or UTF-8 BOM for non-ASCII scripts.
Plan/Verify must not install, upgrade, accept agreements or change persistent settings.
Never force upgrade, uninstall an existing app, disable security, bypass package hashes, change machine execution policy, configure Git identity or enable WSL automatically.
Only the fixed official package catalogue and official extension IDs may be installed, after consent.
Preserve installer exit codes; successful invocation without successful detection is not a successful install.
Do not commit real tokens, paths, raw installer logs or personal data.
Run tests/run.ps1 in Windows PowerShell 5.1 and PowerShell 7. CI/mock checks are not clean-PC installation evidence.
Current author: MITCHELL. PMO NOT_DISPATCHED. IVA NOT_RUN unless a separate result proves otherwise.
