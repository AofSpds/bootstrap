"""Targeted support-policy guards. Synthetic OS boundaries; no real installer calls."""
import unittest
import test_bootstrap as existing


class PlatformPolicyTests(unittest.TestCase):
    def setUp(self):
        self.fixture = existing.BootstrapTests()
        self.fixture.setUp()

    def tearDown(self):
        self.fixture.tearDown()

    def test_macos14_install_stops_before_brew_or_lock(self):
        f = self.fixture
        out = f.run_app('--mode', 'Install', '--accept', code=2, F_VERSION='14.8.9')
        self.assertIn('MACOS_15_REQUIRED_FOR_INSTALL', out)
        self.assertEqual(f.calls(), '')
        self.assertFalse((f.home / '.mitchell-bootstrap').exists())

    def test_macos14_intel_optin_cannot_bypass_os_guard(self):
        f = self.fixture
        out = f.run_app('--mode', 'Install', '--accept', '--allow-unverified-intel',
                        code=2, F_VERSION='14.8', F_ARCH='x86_64', F_ARM='0')
        self.assertIn('MACOS_15_REQUIRED_FOR_INSTALL', out)
        self.assertEqual(f.calls(), '')

    def test_macos14_plan_diagnoses_without_install(self):
        f = self.fixture
        out = f.run_app('--mode', 'Plan', code=2, F_VERSION='14.8')
        self.assertIn('MACOS_14_DIAGNOSTIC_ONLY', out)
        self.assertEqual(out.count('\tPLANNED\t'), 5)
        f.no_install()

    def test_macos14_verify_does_not_claim_supported_install(self):
        f = self.fixture
        f.installed()
        out = f.run_app('--mode', 'Verify', code=2, F_VERSION='14.8')
        self.assertIn('MACOS_14_DIAGNOSTIC_ONLY', out)
        f.no_install()

    def test_macos14_blocks_mobile_and_extension_writes(self):
        f = self.fixture
        f.installed()
        f.run_app('--mode', 'Install', '--profile', 'Mobile', '--ai', 'Both',
                  '--accept', code=2, F_VERSION='14.8')
        self.assertEqual(f.calls(), '')

    def test_macos15_native_install_keeps_existing_consent_contract(self):
        f = self.fixture
        f.run_app('--mode', 'Install', code=2, F_VERSION='15.0')
        f.no_install()
        out = f.run_app('--mode', 'Install', '--accept', F_VERSION='15.0')
        self.assertEqual(out.count('\tINSTALLED\t'), 5)

    def test_supported_install_floor_in_usage(self):
        out = self.fixture.run_app('--help')
        self.assertIn('macOS 15+', out)
        self.assertIn('diagnostic Plan/Verify only', out)

    def test_macos13_not_reclassified_as_diagnostic_support(self):
        f = self.fixture
        out = f.run_app('--mode', 'Plan', code=2, F_VERSION='13.7')
        self.assertIn('MACOS_14_REQUIRED', out)
        self.assertEqual(f.calls(), '')


if __name__ == '__main__':
    unittest.main(verbosity=2)
