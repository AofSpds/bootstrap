"""MAC-F001..F003 regressions. Run as a normal user; no real brew/code/installer.

Bash engine and App/lock filesystem checks are real. Platform/package/extension
commands are fixtures. On Linux only plutil extraction is replaced by plistlib.
MAC_TEST_PRODUCT_ROOT selects an old source for controlled defect reproduction;
it is a test harness option, never a production bypass.
"""
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(os.environ.get('MAC_TEST_PRODUCT_ROOT', Path(__file__).resolve().parents[2])).resolve()
DRIVER = (ROOT / 'tests/macos/driver.sh').read_text().rsplit('bm_main "$@"', 1)[0]
CORE = ['git', 'github', 'gh', 'visual-studio-code', 'node@24']
APP = 'MITCHELL Synthetic 91738.app'

EXTENSION_BOUNDARY = r'''
bm_code() {
  printf 'code %s\n' "$*" >> "$FIXTURE/calls"
  case "$1" in
    --list-extensions)
      local n=0
      [ ! -f "$FIXTURE/list-count" ] || n=$(cat "$FIXTURE/list-count")
      n=$((n+1)); printf '%s' "$n" > "$FIXTURE/list-count"
      if [ "${FAIL_QUERY_AT:-never}" = "$n" ]; then
        printf '%s' "${PARTIAL_OUTPUT:-}"
        printf '%s' 'synthetic-secret /private/fixture' >&2
        return 74
      fi
      cat "$FIXTURE/extensions" ;;
    --install-extension)
      [ "${INSTALL_HAS_EFFECT:-1}" != 1 ] || printf '%s\n' "$2" >> "$FIXTURE/extensions"
      return "${INSTALL_EXIT:-0}" ;;
    *) return 99 ;;
  esac
}
'''

class Cases(unittest.TestCase):
    def setUp(self):
        if os.geteuid() == 0:
            self.fail('Run permission fixtures as a non-root user; root is not valid evidence')
        self.tmp = tempfile.TemporaryDirectory(prefix='mac-fixed 한글 ')
        self.root = Path(self.tmp.name)
        self.home = self.root / 'home 사용자'
        self.home.mkdir()
        self.system = self.root / 'system'
        self.system.mkdir()
        self.repair = []
        for name in ['tools', 'receipts', 'extensions', 'calls']:
            (self.root/name).write_text('')
        self.env = {k:v for k,v in os.environ.items() if not k.startswith(('F_', 'FAIL_QUERY_', 'PARTIAL_OUTPUT', 'INSTALL_'))}
        self.env.update(HOME=str(self.home), FIXTURE=str(self.root))
    def tearDown(self):
        for p in reversed(self.repair):
            p.chmod(0o700)
        self.tmp.cleanup()
    def deny(self, path, mode):
        self.repair.append(path)
        path.chmod(mode)
    def setup_core(self):
        for name in ['tools', 'receipts']:
            (self.root/name).write_text('\n'.join(CORE)+'\n')
    def shell(self, script, *args, code=0, private=False, **extra):
        p = subprocess.run(['/bin/bash', '-c', script, 'fixture', str(ROOT), *map(str,args)],
            env={**self.env, **extra}, text=True, capture_output=True, timeout=15)
        self.assertEqual(p.returncode, code, p.stdout+p.stderr)
        if private:
            for forbidden in [str(self.home), 'synthetic-secret', '/private/fixture']:
                self.assertNotIn(forbidden, p.stdout+p.stderr)
        return p
    def engine(self, overlay='', code=0, **extra):
        driver = self.root/'driver.sh'
        driver.write_text(DRIVER + overlay + '\nbm_main "$@"\nexit $?\n')
        return self.shell('/bin/bash "$2" "$1" --mode Install --accept --ai "${TEST_AI:-None}"',
            driver, code=code, private=True, **extra)
    def calls(self): return (self.root/'calls').read_text()
    def make_app(self, base=None, app=APP):
        p=(base or self.home/'Applications')/app
        (p/'Contents/MacOS').mkdir(parents=True)
        (p/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'synthetic.fixture','CFBundleExecutable':'fixture'}))
        (p/'Contents/MacOS/fixture').write_text('fixture bytes only; never executed\n')
        (p/'Contents/MacOS/fixture').chmod(0o700)
        return p
    def plist_shim(self):
        # Use native Apple plutil on Mac; Linux lacks it. No product files edited.
        if os.uname().sysname == 'Darwin': return ''
        parser=self.root/'read-plist.py'
        parser.write_text('import plistlib,sys\ntry:\n v=plistlib.load(open(sys.argv[2],"rb"))[sys.argv[1]]\n print(v,end="")\nexcept Exception: sys.exit(1)\n')
        return 'bm_app_field() { python3 "$FIXTURE/read-plist.py" "$1" "$2" 2>/dev/null; }\n'
    def apps(self, code=0, first=None, second=None):
        return self.shell('. "$1/scripts/macos/platform.sh"\n'+self.plist_shim()+
            '\nbm_find_app_in "$2" "$3" "$4"', APP, first or self.system,
            second or self.home/'Applications', code=code)

class ExtensionCases(Cases):
    def extensions(self, code=0, **env):
        self.setup_core()
        return self.engine(EXTENSION_BOUNDARY, code=code, TEST_AI='Both', **env)
    def test_f001_existing_second_after_failed_refresh(self):
        (self.root/'extensions').write_text('anthropic.claude-code\n')
        out=self.extensions(code=1, FAIL_QUERY_AT='2')
        self.assertEqual(self.calls().count('--install-extension'),1)
        self.assertNotIn('--install-extension anthropic.claude-code',self.calls())
        self.assertIn('EXTENSION_QUERY_FAILED',out.stdout)
    def test_initial_query_failure_blocks_all(self):
        self.extensions(code=1, FAIL_QUERY_AT='1')
        self.assertNotIn('--install-extension',self.calls())
    def test_partial_failed_query_is_not_inventory(self):
        self.extensions(code=1, FAIL_QUERY_AT='2', PARTIAL_OUTPUT='unrelated.fixture\n')
        self.assertEqual(self.calls().count('--install-extension'),1)
    def test_both_missing_blocks_second_on_query_error(self):
        self.extensions(code=1, FAIL_QUERY_AT='2')
        self.assertEqual(self.calls().count('--install-extension'),1)
    def test_healthy_refresh_installs_both_once(self):
        self.extensions()
        self.assertEqual(self.calls().count('--install-extension'),2)
        self.extensions()
        self.assertEqual(self.calls().count('--install-extension'),2)
    def test_rerun_refreshes_and_preserves_prior_effect(self):
        self.extensions(code=1, FAIL_QUERY_AT='2')
        self.extensions()
        self.assertEqual(self.calls().count('--install-extension openai.chatgpt'),1)
        self.assertEqual(self.calls().count('--install-extension anthropic.claude-code'),1)
    def test_failed_install_and_failed_refresh_blocks_second(self):
        out=self.extensions(code=1, INSTALL_EXIT='42', FAIL_QUERY_AT='2')
        self.assertIn('EXTENSION_EXIT_42',out.stdout)
        self.assertEqual(self.calls().count('--install-extension'),1)
    def test_failed_install_then_successful_refresh_can_continue(self):
        self.extensions(code=1, INSTALL_EXIT='42')
        self.assertEqual(self.calls().count('--install-extension'),2)
    def test_empty_successful_list_is_valid(self):
        out=self.extensions(code=1, INSTALL_HAS_EFFECT='0')
        self.assertEqual(self.calls().count('--install-extension'),2)
        self.assertNotIn('EXTENSION_QUERY_FAILED',out.stdout)

class AppCases(Cases):
    def test_f002_actual_inaccessible_home_parent_not_missing(self):
        p=self.make_app()
        self.deny(p.parent,0)
        out=self.shell('. "$1/scripts/macos/platform.sh"; bm_find_app "$2"',APP,code=5,private=True)
        self.assertEqual(out.stdout,'')
    def test_existing_user_app(self):
        p=self.make_app();self.assertEqual(self.apps().stdout,str(p))
    def test_existing_system_app(self):
        p=self.make_app(self.system);self.assertEqual(self.apps().stdout,str(p))
    def test_two_healthy_apps_preserve_preference(self):
        p=self.make_app(self.system);self.make_app();self.assertEqual(self.apps().stdout,str(p))
    def test_absent_app_in_existing_directories(self):
        (self.home/'Applications').mkdir();self.apps(code=2)
    def test_absent_user_applications(self): self.apps(code=2)
    def test_absent_multiple_parent_components(self): self.apps(code=2,second=self.home/'never'/'created'/'Applications')
    def test_searchable_but_unreadable_missing_parent_fails_closed(self):
        p=self.home/'Applications';p.mkdir();self.deny(p,0o100);self.apps(code=5)
    def test_healthy_first_does_not_hide_second_error(self):
        self.make_app(self.system);p=self.home/'Applications';p.mkdir();self.deny(p,0);self.apps(code=5)
    def test_first_error_does_not_hide_healthy_second(self):
        self.make_app();self.deny(self.system,0);self.apps(code=5)
    def test_broken_app_symlink_not_missing(self):
        p=self.home/'Applications';p.mkdir();(p/APP).symlink_to(self.root/'absent');self.apps(code=3)
    def test_broken_parent_symlink_not_missing(self):
        (self.home/'Applications').symlink_to(self.root/'absent');self.apps(code=5)
    def test_regular_file_parent_not_missing(self):
        (self.home/'Applications').write_text('not directory');self.apps(code=5)
    def test_malformed_plist_preserved(self):
        p=self.make_app();(p/'Contents/Info.plist').write_text('not plist');self.apps(code=3)
    def test_missing_executable_preserved(self):
        p=self.make_app();(p/'Contents/MacOS/fixture').unlink();self.apps(code=3)
    def test_unsearchable_bundle_preserved(self):
        p=self.make_app();self.deny(p,0);self.apps(code=3)
    def test_special_characters_are_literal_and_no_recursive_scan(self):
        p=self.home/'literal[?]*\\\n';p.mkdir()
        # An unreadable unrelated subtree must not be traversed.
        child=p/'unrelated';child.mkdir();self.deny(child,0)
        self.apps(code=2,second=p/'absent[?]*\\')
    def test_receipt_only_keeps_install_blocked(self):
        self.setup_core();(self.root/'tools').write_text('git\ngh\nvisual-studio-code\nnode@24\n')
        self.engine(code=2);self.assertNotIn('homebrew/cask/github',self.calls())
    def test_app_error_blocks_brew_in_real_engine(self):
        self.setup_core();p=self.make_app(app='GitHub Desktop.app');self.deny(p.parent,0)
        overlay=self.plist_shim()+r'''
bm_find_app() { bm_find_app_in "$1" "$FIXTURE/system" "$HOME/Applications"; }
'''
        out=self.engine(overlay,code=1)
        self.assertIn('APP_PATH_QUERY_FAILED',out.stdout)
        self.assertNotIn('install ',self.calls())
    def test_restored_access_reuses_app_without_install(self):
        self.setup_core();p=self.make_app(app='GitHub Desktop.app');self.make_app(app='Visual Studio Code.app')
        self.deny(p.parent,0)
        overlay=self.plist_shim()+'bm_find_app() { bm_find_app_in "$1" "$FIXTURE/system" "$HOME/Applications"; }\n'
        self.engine(overlay,code=1)
        p.parent.chmod(0o700);self.engine(overlay)
        self.assertNotIn('install ',self.calls())

class LockCases(Cases):
    def test_f003_lock_base_mkdir_error_has_no_raw_path(self):
        self.setup_core();self.deny(self.home,0o500)
        out=self.engine(code=2)
        self.assertIn('INSTALL_LOCKED_OR_UNSAFE',out.stdout)
        self.assertEqual(out.stderr,'');self.assertNotIn('install ',self.calls())
    def test_existing_safe_base_and_release(self):
        self.setup_core();p=self.home/'.mitchell-bootstrap';p.mkdir();self.engine()
        self.assertTrue(p.is_dir());self.assertFalse((p/'install.lock').exists())
    def test_existing_lock_not_deleted(self):
        self.setup_core();p=self.home/'.mitchell-bootstrap/install.lock';p.mkdir(parents=True)
        self.engine(code=2);self.assertTrue(p.is_dir());self.assertNotIn('install ',self.calls())
    def test_symlink_base_and_target_preserved(self):
        self.setup_core();p=self.home/'.mitchell-bootstrap';p.symlink_to(self.system)
        self.engine(code=2);self.assertTrue(p.is_symlink());self.assertFalse((self.system/'install.lock').exists())
    def test_regular_file_base_preserved(self):
        self.setup_core();p=self.home/'.mitchell-bootstrap';p.write_text('preserve')
        self.engine(code=2);self.assertEqual(p.read_text(),'preserve')
    def test_unwritable_existing_base_has_no_raw_path(self):
        self.setup_core();p=self.home/'.mitchell-bootstrap';p.mkdir();self.deny(p,0o500)
        out=self.engine(code=2);self.assertEqual(out.stderr,'');self.assertNotIn('install ',self.calls())

if __name__ == '__main__': unittest.main(verbosity=2)
