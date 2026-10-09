"""Offline regression coverage for deployment and compression safety."""
import importlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.agents/skills/caveman-compress'))
compress = importlib.import_module('scripts.compress')
validate = importlib.import_module('scripts.validate')


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base / 'repo'
        self.config = self.base / 'config'
        (self.repo / 'hypr/sub').mkdir(parents=True)
        (self.repo / 'hypr/sub/config').write_text('new')
        self.config.mkdir()
        self.env = {**os.environ, 'DOTFILES_DIR': str(self.repo),
                    'HOME_TARGET': str(self.base / 'home'),
                    'CONFIG_ROOT_TARGET': str(self.config),
                    'BIN_ROOT_TARGET': str(self.base / 'local'),
                    'STOW_BACKUP_ROOT': str(self.base / 'backups'),
                    'STOW_TIMESTAMP': 'same'}

    def run_deploy(self):
        return subprocess.run(['bash', str(ROOT / 'modules/stow.sh')],
                              env=self.env, capture_output=True, text=True)

    def test_foreign_symlink_and_idempotence(self):
        external = self.base / 'external'
        external.mkdir()
        (external / 'config').write_text('original')
        (self.config / 'hypr').mkdir()
        (self.config / 'hypr/sub').symlink_to(external)
        self.assertEqual(self.run_deploy().returncode, 0)
        self.assertEqual((external / 'config').read_text(), 'original')
        self.assertTrue((self.config / 'hypr/sub/config').is_symlink())
        self.assertEqual(self.run_deploy().returncode, 0)

    def test_failure_restores_directory_symlink(self):
        external = self.base / 'external'
        external.mkdir()
        (external / 'config').write_text('original')
        (self.config / 'hypr').mkdir()
        target = self.config / 'hypr/sub'
        target.symlink_to(external)
        commands = self.base / 'commands'
        commands.mkdir()
        fake = commands / 'ln'
        fake.write_text('#!/bin/sh\nexit 42\n')
        fake.chmod(0o755)
        self.env['PATH'] = str(commands) + ':' + self.env['PATH']
        self.assertNotEqual(self.run_deploy().returncode, 0)
        self.assertTrue(target.is_symlink())
        self.assertEqual((target / 'config').read_text(), 'original')

    def test_ignored_readme_and_unique_backups(self):
        (self.repo / 'hypr/README.md').write_text('repo docs')
        (self.config / 'hypr').mkdir()
        (self.config / 'hypr/README.md').write_text('local docs')
        self.assertEqual(self.run_deploy().returncode, 0)
        self.assertEqual(self.run_deploy().returncode, 0)
        self.assertEqual((self.config / 'hypr/README.md').read_text(), 'local docs')
        self.assertEqual(len(list((self.base / 'backups').iterdir())), 2)


class CompressionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.file = Path(self.tmp.name) / 'notes.md'

    def test_retry_exception_preserves_original(self):
        original = b'```bash\necho safe\n```\n'
        self.file.write_bytes(original)
        with patch.object(compress, 'call_claude', side_effect=['```bash\necho changed\n```', RuntimeError('offline')]):
            with self.assertRaises(RuntimeError):
                compress.compress_file(self.file)
        self.assertEqual(self.file.read_bytes(), original)
        self.assertFalse(self.file.with_name('notes.original.md').exists())

    def test_refusal_and_invalid_encoding_preserve_input(self):
        self.file.write_text('Important instructions.')
        with patch.object(compress, 'call_claude', return_value='Sorry, I cannot process this request.'):
            self.assertFalse(compress.compress_file(self.file))
        self.assertEqual(self.file.read_text(), 'Important instructions.')
        self.file.write_bytes(b'bad\xff')
        with self.assertRaises(UnicodeDecodeError):
            compress.compress_file(self.file)
        self.assertEqual(self.file.read_bytes(), b'bad\xff')

    def test_valid_output_has_exact_backup(self):
        original = b'# Notes\r\nPlease read `/etc/hosts`.\r\n'
        self.file.write_bytes(original)
        with patch.object(compress, 'call_claude', return_value='# Notes\nRead `/etc/hosts`.\n'):
            self.assertTrue(compress.compress_file(self.file))
        self.assertEqual(self.file.with_name('notes.original.md').read_bytes(), original)

    def test_headings_paths_urls_and_multibackticks(self):
        for orig, comp in [('# Original\n', '# Changed\n'),
                           ('Read /etc/hosts', 'Read /tmp/other'),
                           ('https://example.com https://example.com', 'https://example.com'),
                           ('Use ``a`b``', 'Use ``a`c``')]:
            self.assertFalse(validate.validate_text(orig, comp).is_valid)

    def test_validator_cli_failure_status(self):
        self.file.write_text('# Original\n')
        other = self.file.with_name('other.md')
        other.write_text('# Changed\n')
        result = subprocess.run([sys.executable, '-B', str(ROOT / '.agents/skills/caveman-compress/scripts/validate.py'),
                                 str(self.file), str(other)], capture_output=True)
        self.assertEqual(result.returncode, 1)


class LocaleTests(unittest.TestCase):
    def test_invalid_inherited_overrides(self):
        env = {**os.environ, 'ZDOTDIR': str(ROOT / 'zsh'), 'LANG': 'invalid_LOCALE',
               'LC_ALL': 'invalid_LOCALE', 'LC_CTYPE': 'invalid_LOCALE'}
        result = subprocess.run(['zsh', '-c', 'print -r -- "$LANG ${LC_ALL-unset} ${LC_CTYPE-unset}"; bsdtar --version'],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith('C.UTF-8 unset unset'))
        self.assertNotIn('Failed to set default locale', result.stderr)

    def test_valid_utf8_alias_preserved(self):
        env = {**os.environ, 'ZDOTDIR': str(ROOT / 'zsh'), 'LANG': 'C.UTF-8',
               'LC_ALL': 'C.UTF-8', 'LC_CTYPE': 'C.UTF-8'}
        result = subprocess.run(['zsh', '-c', 'print -r -- "$LANG $LC_ALL $LC_CTYPE"'],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.stdout.strip(), 'C.UTF-8 C.UTF-8 C.UTF-8')


class ScreenshotTests(unittest.TestCase):
    def test_all_modes_without_wayland(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            for cmd in ('hyprshot', 'grim', 'satty'):
                script = base / cmd
                script.write_text('#!/bin/sh\nprintf "%s\\n" "$0 $*" >> "$CALL_LOG"\n'
                                  + ('printf png\n' if cmd == 'hyprshot' else '')
                                  + ('printf png > "$1"\n' if cmd == 'grim' else ''))
                script.chmod(0o755)
            env = {**os.environ, 'PATH': str(base) + ':' + os.environ['PATH'],
                   'CALL_LOG': str(base / 'calls'), 'XDG_PICTURES_DIR': str(base)}
            for mode in ('region', 'smart', 'window', 'fullscreen'):
                result = subprocess.run(['bash', str(ROOT / 'bin/bin/zen0x-capture-screenshot'), mode],
                                        env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            calls = (base / 'calls').read_text()
            self.assertIn('-m window --raw', calls)
            self.assertEqual(calls.count('/satty '), 4)


if __name__ == '__main__':
    unittest.main()
