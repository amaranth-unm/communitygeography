#!/usr/bin/env python3
"""Resize/compress tracked JPEGs and PNGs while preserving Cascade asset URLs.

Adapted from Xanthan's ImageMagick workflow at 5e106aac8ba5c93467d638db02ffe8430346ecd6.
Preview encodes temporary candidates to measure real savings. Apply is explicit;
all candidates are checked before any originals are replaced.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
STATE = ROOT / '.github/image-optimization-state.json'


def run(command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f'Command failed: {command[0]}')
    return result.stdout


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def positive(value):
    number = int(value)
    if not 1 <= number <= 20000:
        raise argparse.ArgumentTypeError('Enter an integer between 1 and 20000.')
    return number


def write_report(args, rows):
    changed = [row for row in rows if row['status'] == 'smaller']
    before = sum(row['before'] for row in rows)
    after = sum(row.get('after', row['before']) for row in rows)
    report = {'mode': 'apply' if args.apply else 'preview',
              'folder': args.base_dir, 'max_edge': args.max_edge, 'quality': args.quality,
              'images': len(rows), 'changed': len(changed),
              'bytes_before': before, 'bytes_after': after,
              'bytes_saved': before - after, 'files': rows}
    lines = ['## Image optimization', '',
             '**Applied and ready to commit.**' if args.apply else '**Preview only — no repository files changed.**', '',
             f"Images checked: **{len(rows)}**. Smaller candidates: **{len(changed)}**.",
             f"Total: **{before / 1048576:.2f} MiB → {after / 1048576:.2f} MiB** "
             f"({(before - after) / 1048576:.2f} MiB saved).", '',
             'Filenames and formats are preserved. Preview measures file sizes; review visual quality before choosing to apply.', '',
             '| File | Before (KiB) | After (KiB) | Result |',
             '| --- | ---: | ---: | --- |']
    for row in rows:
        label = row['path'].replace('|', '\\|').replace('\n', ' ')
        lines.append(f"| {label} | {row['before'] / 1024:.1f} | "
                     f"{row.get('after', row['before']) / 1024:.1f} | {row['status']} |")
    summary = '\n'.join(lines) + '\n'
    print(summary)
    if args.report:
        Path(args.report).write_text(json.dumps(report, indent=2) + '\n')
    if args.summary:
        with Path(args.summary).open('a') as output:
            output.write(summary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-dir', default='.', help='Folder relative to the repository (default: repository root).')
    parser.add_argument('--recursive', action='store_true', help='Include subfolders.')
    parser.add_argument('--max-edge', type=positive, default=1600)
    parser.add_argument('--quality', type=positive, default=85, help='JPEG quality, 1–100 (default: 85).')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true', help='Replace originals; default is preview only.')
    mode.add_argument('--preview', action='store_true', help='Measure savings without changing files (default).')
    parser.add_argument('--report', help='Optional JSON report path outside the repository.')
    parser.add_argument('--summary', help='Optional Markdown summary path outside the repository.')
    args = parser.parse_args()
    if args.quality > 100:
        parser.error('JPEG quality must be between 1 and 100.')
    folder = (ROOT / args.base_dir).resolve()
    if Path(args.base_dir).is_absolute() or not folder.is_relative_to(ROOT) or not folder.is_dir():
        parser.error('Choose an existing folder inside this repository.')
    for destination in (args.report, args.summary):
        if destination and Path(destination).resolve().is_relative_to(ROOT):
            parser.error('Write reports outside the repository, for example in /tmp.')
    if shutil.which('magick'):
        convert, identify = ['magick'], ['magick', 'identify']
    elif shutil.which('convert') and shutil.which('identify'):
        convert, identify = ['convert'], ['identify']
    else:
        raise RuntimeError('ImageMagick is required. Install it with brew install imagemagick or apt-get install imagemagick.')
    names = run(['git', 'ls-files', '-z']).split('\0')
    files = []
    for name in names:
        path = ROOT / name
        if not name or path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(folder):
            continue
        if not args.recursive and path.parent != folder:
            continue
        # Identify by file signature: Cascade published some images without extensions.
        with path.open('rb') as source:
            signature = source.read(8)
        if signature.startswith(b'\xff\xd8\xff') or signature == b'\x89PNG\r\n\x1a\n':
            files.append((name, path))
    if args.apply:
        dirty = set(run(['git', 'diff', '--name-only', '-z', 'HEAD']).split('\0'))
        if dirty.intersection(name for name, _ in files) or '.github/image-optimization-state.json' in dirty:
            raise RuntimeError('Commit the selected images and optimization state before applying; Git history preserves the originals.')
    state = json.loads(STATE.read_text()) if STATE.exists() else {'version': 1, 'images': {}}
    settings = {'max_edge': args.max_edge, 'quality': args.quality}
    rows, replacements = [], []
    with tempfile.TemporaryDirectory(prefix='xanthan-images-') as temporary:
        for number, (name, path) in enumerate(files):
            before = path.stat().st_size
            source_hash = digest(path)
            row = {'path': name, 'before': before, 'status': 'already processed'}
            rows.append(row)
            if state['images'].get(name) == dict(settings, sha256=source_hash):
                continue
            info = run(identify + ['-format', '%m %w %h %n\n', str(path)]).strip().splitlines()
            if len(info) != 1 or info[0].split()[-1] != '1':
                row['status'] = 'skipped: multiple frames'
                continue
            image_format, width, height, _ = info[0].split()
            if image_format not in ('JPEG', 'PNG'):
                row['status'] = 'skipped: unsupported format'
                continue
            if before < 300000 and max(int(width), int(height)) <= args.max_edge:
                row['status'] = 'already small'
                continue
            candidate = Path(temporary) / str(number)
            command = convert + [str(path), '-auto-orient', '-resize', f'{args.max_edge}x{args.max_edge}>']
            if image_format == 'JPEG':
                command += ['-quality', str(args.quality)]
            # Explicit encoder also supports extensionless and trailing-dot filenames.
            command += [f'{image_format}:{candidate}']
            run(command)
            result = run(identify + ['-format', '%m %w %h %n', str(candidate)]).split()
            if len(result) != 4 or result[0] != image_format or result[3] != '1' or max(map(int, result[1:3])) > args.max_edge:
                raise RuntimeError(f'Unexpected encoded image: {name}; originals have not been changed.')
            if candidate.stat().st_size >= before:
                row['status'] = 'kept original: no size saving'
                continue
            row.update(after=candidate.stat().st_size, status='smaller', dimensions=[int(result[1]), int(result[2])])
            replacements.append((name, path, candidate, source_hash))
        if args.apply and replacements:
            for name, path, _, source_hash in replacements:
                if digest(path) != source_hash:
                    raise RuntimeError(f'Image changed during processing: {name}; originals have not been replaced.')
            for name, path, candidate, _ in replacements:
                # Copy next to the destination, then replace atomically on its filesystem.
                with tempfile.NamedTemporaryFile(dir=path.parent, prefix='.optimized-', delete=False) as output:
                    staged = Path(output.name)
                try:
                    shutil.copyfile(candidate, staged)
                    os.chmod(staged, path.stat().st_mode & 0o777)
                    os.replace(staged, path)
                finally:
                    staged.unlink(missing_ok=True)
                state['images'][name] = dict(settings, sha256=digest(path))
            STATE.parent.mkdir(parents=True, exist_ok=True)
            STATE.write_text(json.dumps(state, indent=2, sort_keys=True) + '\n')
        write_report(args, rows)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError, OSError) as error:
        print(f'Image optimization failed: {error}', file=sys.stderr)
        sys.exit(1)
