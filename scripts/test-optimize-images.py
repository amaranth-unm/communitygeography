#!/usr/bin/env python3
"""Exercise actual image encoding in an isolated repository; never edit site media."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parent
CONVERT = ['magick'] if shutil.which('magick') else ['convert']
IDENTIFY = ['magick', 'identify'] if shutil.which('magick') else ['identify']


class ImageOptimizationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='image-workflow-test-')
        self.addCleanup(self.temporary.cleanup)
        self.output = Path(self.temporary.name)
        self.repo = self.output / 'repo'
        (self.repo / 'scripts').mkdir(parents=True)
        for name in ('optimize-images.sh', 'optimize-images.py'):
            shutil.copyfile(SOURCE / name, self.repo / 'scripts' / name)
        self.command(['git', 'init', '-q'])
        self.command(['git', 'config', 'user.name', 'Image test'])
        self.command(['git', 'config', 'user.email', 'test@example.invalid'])
        self.command(CONVERT + ['-size', '160x80', 'plasma:fractal', '-quality', '100', 'photo with spaces.jpg'])
        self.command(CONVERT + ['-size', '160x80', 'plasma:fractal', '-alpha', 'set', '-channel', 'A',
                               '-evaluate', 'set', '50%', '+channel', 'photo with spaces.png'])
        shutil.copyfile(self.repo / 'photo with spaces.jpg', self.repo / 'portrait')
        shutil.copyfile(self.repo / 'photo with spaces.png', self.repo / 'legacy.')
        (self.repo / 'content.md').write_text('[Photo](photo with spaces.jpg) ![Portrait](portrait)')
        (self.repo / 'data.yml').write_text('image: photo with spaces.png\n')
        self.commit()
        # These must not be considered even when the selected folder is the root.
        (self.repo / '_site').mkdir()
        shutil.copyfile(self.repo / 'portrait', self.repo / '_site/generated.jpg')
        shutil.copyfile(self.repo / 'portrait', self.repo / 'untracked.jpg')

    def command(self, command, ok=True):
        result = subprocess.run(command, cwd=self.repo, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
        return result

    def commit(self):
        self.command(['git', 'add', 'scripts', '*.jpg', '*.png', 'portrait', 'legacy.', 'content.md', 'data.yml'])
        self.command(['git', 'commit', '-qm', 'Test fixture'])

    def optimize(self, *args, ok=True):
        return self.command(['bash', 'scripts/optimize-images.sh', '--recursive', '--max-edge', '32',
                             '--report', str(self.output / 'report.json'), *args], ok=ok)

    def hashes(self):
        return {str(p.relative_to(self.repo)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.repo.rglob('*') if p.is_file() and '.git' not in p.parts}

    def test_preview_is_read_only_and_includes_legacy_names(self):
        before = self.hashes()
        self.optimize('--preview')
        self.assertEqual(before, self.hashes())
        report = json.loads((self.output / 'report.json').read_text())
        self.assertEqual(report['images'], 4)
        self.assertEqual(report['changed'], 4)
        self.assertGreater(report['bytes_saved'], 0)

    def test_apply_preserves_paths_formats_transparency_and_skips_repeat_work(self):
        before = self.hashes()
        self.optimize('--apply')
        for name, expected in [('photo with spaces.jpg', 'JPEG'), ('photo with spaces.png', 'PNG'),
                               ('portrait', 'JPEG'), ('legacy.', 'PNG')]:
            info = self.command(IDENTIFY + ['-format', '%m %w %h', name]).stdout.split()
            self.assertEqual(info[0], expected)
            self.assertLessEqual(max(map(int, info[1:])), 32)
        alpha = self.command(IDENTIFY + ['-format', '%[opaque]', 'photo with spaces.png']).stdout
        self.assertEqual(alpha.lower(), 'false')
        after = self.hashes()
        for name in ('content.md', 'data.yml', 'untracked.jpg', '_site/generated.jpg'):
            self.assertEqual(before[name], after[name])
        self.command(['git', 'add', '-u'])
        self.command(['git', 'add', '.github/image-optimization-state.json'])
        self.command(['git', 'commit', '-qm', 'Optimized fixtures'])
        self.optimize('--apply')
        self.assertEqual(after, self.hashes())
        self.assertEqual(json.loads((self.output / 'report.json').read_text())['changed'], 0)

    def test_failed_image_does_not_replace_earlier_candidates(self):
        (self.repo / 'zz-corrupt.jpg').write_bytes(b'\xff\xd8\xffnot a valid image')
        self.command(['git', 'add', 'zz-corrupt.jpg'])
        self.command(['git', 'commit', '-qm', 'Corrupt fixture'])
        before = self.hashes()
        self.assertNotEqual(self.optimize('--apply', ok=False).returncode, 0)
        self.assertEqual(before, self.hashes())

    def test_invalid_scope_and_dirty_images_are_rejected(self):
        before = self.hashes()
        for args in [('--base-dir', '..'), ('--base-dir', str(self.repo)), ('--quality', '101'), ('--max-edge', '0')]:
            self.assertNotEqual(self.optimize(*args, ok=False).returncode, 0)
        self.assertEqual(before, self.hashes())
        with (self.repo / 'portrait').open('ab') as image:
            image.write(b'changed')
        before = self.hashes()
        self.assertNotEqual(self.optimize('--apply', ok=False).returncode, 0)
        self.assertEqual(before, self.hashes())


if __name__ == '__main__':
    unittest.main()
