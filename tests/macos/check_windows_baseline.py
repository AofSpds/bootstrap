"""Ensure macOS additions never silently alter the approved Windows baseline."""
import subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {'.gitattributes': ['100644', '79d95b962de147c2be69cd61bf992b2b5adca3da'], '.github/workflows/ci.yml': ['100644', 'e0bc3daaea7358383852a3177f2263748ea2e691'], '.gitignore': ['100644', '022ca9fcdd7e4d33a5e79961ebe45194361aaf6c'], 'AGENTS.md': ['100644', 'a6d619c63f0c9cdb6e2625753be22203f9dc7332'], 'bootstrap.bat': ['100644', '4e4fa402b00f80970019b8ba0ec79910d5418c07'], 'bootstrap.ps1': ['100644', 'b368356bd1f4a2eb982d8aa0c256d3e1e6815f7e'], 'config/packages.psd1': ['100644', '1b705ef2f59cc1bfbf7107bdee24cc79a259013f'], 'docs/FIRST_RUN.md': ['100644', '4f08bace127ec6237cadad5230141ab34acc95c8'], 'docs/SOURCES.md': ['100644', 'e75056f452fef591bd1cbf3821e70558706e2999'], 'docs/TESTED_VERSIONS.md': ['100644', '74f08446324906254c20a0a0abc972335e7cd4dc'], 'docs/TROUBLESHOOTING.md': ['100644', 'cf14b6c8b98142434ddad5e347b851a2e910a1fb'], 'scripts/common.ps1': ['100644', '314c12e3b892d64ad8b42e0caa7c1cb0a54007ae'], 'scripts/install-ai.ps1': ['100644', '9898e462413130a23f7f945535c32e4d1bc27613'], 'scripts/install-packages.ps1': ['100644', '76ed5327dff9ce3e1ed7d51b9f309f9901abd805'], 'scripts/preflight.ps1': ['100644', 'f2d93799759fc3925268f83970697eee9084fcf0'], 'scripts/verify.ps1': ['100644', '3c88082e6e60b24bbeb7464d7b2cbaed5e1396de'], 'tests/logs-and-catalogue.ps1': ['100644', '76745fe7912da4bbe987a719e8b790873a4ac48b'], 'tests/run.ps1': ['100644', '72e3841e90684cea45f8a4487ec46c49cf36ae34']}
actual = {}
for line in subprocess.check_output(['git', '-C', str(ROOT), 'ls-tree', '-r', 'HEAD'], text=True).splitlines():
    meta, path = line.split('\t')
    mode, kind, sha = meta.split()
    actual[path] = [mode, sha]
for path, expected in EXPECTED.items():
    if actual.get(path) != expected:
        raise SystemExit('WINDOWS_BASELINE_CHANGED: ' + path)
print('WINDOWS_BASELINE_BLOBS_UNCHANGED=' + str(len(EXPECTED)))
