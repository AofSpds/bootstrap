"""Execute the real Bash engine with isolated OS/package boundaries; not real installation."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
CORE = ['git', 'github', 'gh', 'visual-studio-code', 'node@24']

class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='bootstrap 한글 space ')
        self.root = Path(self.tmp.name)
        self.home = self.root / 'home 사용자'
        self.home.mkdir()
        for name in ['tools', 'receipts', 'extensions', 'calls']:
            (self.root / name).write_text('', encoding='utf-8')
        for name in ['.zprofile', '.zshrc', '.gitconfig']:
            (self.home / name).write_text('PRESERVE\n')
        self.env = {**os.environ, 'FIXTURE': str(self.root), 'HOME': str(self.home)}
        for k in list(self.env):
            if k.startswith('F_'): del self.env[k]
    def tearDown(self):
        for name in ['.zprofile', '.zshrc', '.gitconfig']:
            self.assertEqual((self.home/name).read_text(), 'PRESERVE\n')
        self.tmp.cleanup()
    def installed(self, packages=CORE):
        for name in ['tools', 'receipts']:
            (self.root/name).write_text('\n'.join(packages)+'\n')
    def run_app(self, *args, code=0, **env):
        p = subprocess.run(['/bin/bash', str(ROOT/'tests/macos/driver.sh'), str(ROOT), *args],
                           env={**self.env, **env}, text=True, capture_output=True, timeout=15)
        self.assertEqual(p.returncode, code, p.stdout+p.stderr)
        self.assertNotIn('token-secret', p.stdout+p.stderr)
        self.assertNotIn('password=secret', p.stdout+p.stderr)
        self.assertNotIn('/Users/private', p.stdout+p.stderr)
        return p.stdout
    def calls(self): return (self.root/'calls').read_text()
    def no_install(self): self.assertNotIn('install ', self.calls())
    def test_plan_missing_is_read_only(self):
        out=self.run_app(); self.assertEqual(out.count('\tPLANNED\t'),5); self.no_install()
        self.assertFalse((self.home/'.mitchell-bootstrap').exists())
    def test_verify_missing_requires_action(self):
        self.run_app('--mode','Verify',code=2);self.no_install()
    def test_invalid_argument_precedes_any_probe(self):
        self.run_app('--mode','Bogus',code=2);self.assertEqual(self.calls(),'')
    def test_missing_argument_value(self): self.run_app('--ai',code=2)
    def test_untrusted_optional_rejected(self):
        self.run_app('--optional','$(touch BAD)',code=2);self.assertEqual(self.calls(),'')
    def test_optional_empty_element_rejected(self): self.run_app('--optional','Python,,Docker',code=2)
    def test_help_never_calls_platform(self): self.run_app('--help',F_OS='Linux');self.assertEqual(self.calls(),'')
    def test_wrong_os(self): self.run_app(code=2,F_OS='Linux');self.no_install()
    def test_root_refused(self): self.run_app('--mode','Install','--accept',code=2,F_UID='0');self.no_install()
    def test_invalid_uid(self): self.run_app(code=1,F_UID='unknown');self.no_install()
    def test_old_macos(self): self.run_app(code=2,F_VERSION='13.7');self.no_install()
    def test_malformed_macos(self): self.run_app(code=2,F_VERSION='unknown');self.no_install()
    def test_rosetta_refused(self): self.run_app(code=2,F_TRANSLATED='1');self.no_install()
    def test_x86_on_arm_refused(self): self.run_app(code=2,F_ARCH='x86_64');self.no_install()
    def test_unknown_arch(self): self.run_app(code=2,F_ARCH='ppc64',F_ARM='0');self.no_install()
    def test_intel_plan_allowed_unverified(self):
        self.assertIn('INTEL_DEVICE_UNVERIFIED',self.run_app(F_ARCH='x86_64',F_ARM='0'))
    def test_intel_install_requires_opt_in(self):
        self.run_app('--mode','Install','--accept',code=2,F_ARCH='x86_64',F_ARM='0');self.no_install()
    def test_intel_install_opt_in(self):
        self.run_app('--mode','Install','--accept','--allow-unverified-intel',F_ARCH='x86_64',F_ARM='0')
        self.assertEqual(self.calls().count('install '),5)
    def test_clt_absent_no_brew(self):
        self.run_app(code=2,F_CLT='0');self.assertEqual(self.calls(),'')
    def test_brew_absent_action(self): self.run_app(code=2,F_BREW='0');self.no_install()
    def test_brew_wrong_prefix(self): self.run_app(code=2,F_PREFIX='/tmp/custom');self.no_install()
    def test_malformed_inventory(self):
        (self.root/'receipts').write_text('BAD inventory\n');self.run_app(code=1);self.no_install()
    def test_inventory_error_not_missing(self):
        self.run_app('--mode','Install','--accept',code=1,F_INVENTORY='fail');self.no_install()
    def test_install_no_consent(self):
        self.run_app('--mode','Install',code=2);self.no_install()
    def test_existing_preserved_no_reinstall(self):
        self.installed();self.run_app('--mode','Install','--accept');self.no_install()
    def test_installs_fixed_packages(self):
        out=self.run_app('--mode','Install','--accept');self.assertEqual(out.count('\tINSTALLED\t'),5)
        self.assertIn('install --cask --require-sha homebrew/cask/github',self.calls())
        self.assertIn('install --formula homebrew/core/node@24',self.calls())
    def test_repeat_install_no_additional_installs(self):
        self.run_app('--mode','Install','--accept');first=self.calls().count('install ')
        self.run_app('--mode','Install','--accept');self.assertEqual(first,self.calls().count('install '))
    def test_installer_failure_preserves_code_and_continues(self):
        out=self.run_app('--mode','Install','--accept',code=1,F_INSTALL_FAIL='github')
        self.assertIn('INSTALL_EXIT_42',out);self.assertIn('Node\tINSTALLED',out)
    def test_no_false_success_without_detection(self):
        self.run_app('--mode','Install','--accept',code=1,F_NO_TOOL='gh')
    def test_no_false_success_without_receipt(self):
        self.run_app('--mode','Install','--accept',code=1,F_NO_RECEIPT='gh')
    def test_installed_receipt_without_tool_not_overwritten(self):
        (self.root/'receipts').write_text('gh\n')
        out=self.run_app('--mode','Install','--accept',code=2)
        self.assertIn('INSTALLED_RECEIPT_BUT_TOOL_MISSING',out)
        self.assertNotIn('homebrew/core/gh',self.calls())
    def test_post_install_inventory_failure_blocks_following_installs(self):
        self.run_app('--mode','Install','--accept',code=1,F_AFTER_INVENTORY_FAIL='1')
        self.assertEqual(self.calls().count('install '),1)
    def test_old_node_not_overwritten(self):
        self.installed();self.run_app('--mode','Install','--accept',code=2,F_NODE='v20.9.0');self.no_install()
    def test_node_22_floor(self):
        self.installed();self.run_app(code=2,F_NODE='v22.15.0');self.run_app(F_NODE='v22.16.0')
    def test_node_no_npm(self): self.installed();self.run_app(code=2,F_NPM='0')
    def test_node_path_not_silently_patched(self): self.installed();self.run_app(code=2,F_NODE_PATH='0')
    def test_node_malformed_version_rejected(self): self.installed();self.run_app(code=2,F_NODE='v24.0.0\nsecret')
    def test_broken_existing_app_preserved(self):
        self.installed();self.run_app('--mode','Install','--accept',code=2,F_BROKEN='github');self.no_install()
    def test_symlink_lock_root_refused(self):
        (self.home/'.mitchell-bootstrap').symlink_to(self.root,target_is_directory=True)
        self.run_app('--mode','Install','--accept',code=2);self.no_install()
    def test_existing_lock_refused_no_stale_removal(self):
        p=self.home/'.mitchell-bootstrap/install.lock';p.mkdir(parents=True)
        self.run_app('--mode','Install','--accept',code=2);self.assertTrue(p.exists());self.no_install()
    def test_lock_released_even_installer_failed(self):
        self.run_app('--mode','Install','--accept',code=1,F_INSTALL_FAIL='git')
        self.assertFalse((self.home/'.mitchell-bootstrap/install.lock').exists())
    def test_mobile_requests_only_three_extra_packages(self):
        self.installed();out=self.run_app('--profile','Mobile',code=2)
        self.assertEqual(out.count('\tPLANNED\t'),3);self.assertIn('FULL_XCODE',out);self.assertIn('SDK_SETUP',out);self.no_install()
    def test_mobile_detected_not_build_acceptance(self):
        self.installed(CORE+['temurin@17','cocoapods','android-studio'])
        out=self.run_app('--profile','Mobile',F_XCODE='1',F_SDK='1')
        self.assertIn('NOT_BUILD_ACCEPTANCE',out)
    def test_options_deduplicated(self):
        self.installed();out=self.run_app('--optional','Python,Python,SevenZip')
        self.assertEqual(out.count('\tPLANNED\t'),2)
    def test_optional_formula_vs_cask(self):
        self.installed();self.run_app('--mode','Install','--accept','--optional','PowerShell,SevenZip,Docker')
        self.assertIn('homebrew/core/powershell',self.calls());self.assertIn('homebrew/core/sevenzip',self.calls())
        self.assertIn('homebrew/cask/docker-desktop',self.calls())
    def test_ai_none_does_not_run_code(self): self.installed();self.run_app();self.assertNotIn('code ',self.calls())
    def test_ai_missing_code(self): self.run_app('--ai','Codex',code=2)
    def test_ai_plan_does_not_install(self):
        self.installed();self.run_app('--ai','Both');self.no_install();self.assertNotIn('--install-extension',self.calls())
    def test_ai_verify_missing(self): self.installed();self.run_app('--mode','Verify','--ai','Codex',code=2)
    def test_ai_install_both_then_preserve(self):
        self.installed();self.run_app('--mode','Install','--accept','--ai','Both')
        self.assertEqual(self.calls().count('--install-extension'),2)
        self.run_app('--mode','Install','--accept','--ai','Both')
        self.assertEqual(self.calls().count('--install-extension'),2)
    def test_ai_install_failed(self): self.installed();self.run_app('--mode','Install','--accept','--ai','Codex',code=1,F_EXT_FAIL='1')
    def test_ai_install_no_receipt(self): self.installed();self.run_app('--mode','Install','--accept','--ai','Codex',code=1,F_EXT_NO_DETECT='1')
    def test_ai_inventory_failed(self): self.installed();self.run_app('--ai','Both',code=1,F_EXT_QUERY_FAIL='1')
    def test_invalid_optional_and_ai_never_execute(self):
        self.run_app('--ai','bad.extension',code=2);self.run_app('--optional','--force',code=2);self.assertEqual(self.calls(),'')
    def test_production_wrapper_on_linux_cannot_be_overridden_by_fixture_env(self):
        if os.uname().sysname != 'Linux': self.skipTest('Linux negative OS test')
        p=subprocess.run(['/bin/bash',str(ROOT/'bootstrap.command'),'--mode','Plan'],env=self.env,capture_output=True,text=True)
        self.assertEqual(p.returncode,2);self.assertIn('MACOS_ONLY',p.stdout);self.assertEqual(self.calls(),'')
    def test_brew_wrapper_security_environment_and_exit_status(self):
        stub=self.root/'fake-brew'
        stub.write_text('#!/bin/bash\n[ "${HOMEBREW_NO_AUTO_UPDATE}" = 1 ] || exit 98\n[ "${HOMEBREW_NO_INSTALL_UPGRADE}" = 1 ] || exit 98\n[ "${HOMEBREW_NO_INSTALL_CLEANUP}" = 1 ] || exit 98\n[ "${HOMEBREW_CASK_OPTS+x}" != x ] || exit 98\nexit 17\n')
        stub.chmod(0o700)
        p=subprocess.run(['/bin/bash','-c','. "$1/scripts/macos/platform.sh"; BM_BREW=$2; bm_brew list --formula -1','fixture',str(ROOT),str(stub)],env={**self.env,'HOMEBREW_CASK_OPTS':'--force --no-quarantine'},capture_output=True)
        self.assertEqual(p.returncode,17)
    def test_shell_syntax(self):
        for path in [ROOT/'bootstrap.command',*list((ROOT/'scripts/macos').glob('*.sh')),*list((ROOT/'config/macos').glob('*.sh'))]:
            p=subprocess.run(['/bin/bash','-n',str(path)],capture_output=True,text=True)
            self.assertEqual(p.returncode,0,p.stderr)
    def test_no_destructive_commands_in_production(self):
        text='\n'.join(p.read_text() for p in (ROOT/'scripts/macos').glob('*.sh'))
        for banned in ['rm -rf','sudo ', 'xattr ', 'spctl ', '--force', '--no-quarantine', 'brew upgrade', 'brew link', 'npm install -g']:
            executable='\n'.join(x for x in text.splitlines() if not x.lstrip().startswith('#'))
            self.assertNotIn(banned,executable)

if __name__ == '__main__': unittest.main(verbosity=2)
