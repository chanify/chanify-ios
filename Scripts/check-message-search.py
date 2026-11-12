#!/usr/bin/env python3
"""Exercise the production search worker with isolated on-disk SQLite fixtures."""
from pathlib import Path
import os
import subprocess
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='chanify-search-') as scratch:
    fmdb = ROOT / 'Packages/ChanifyDependencies/Sources/FMDB'
    command = ['xcrun', 'clang', '-fobjc-arc', '-fmodules',
               f'-fmodules-cache-path={scratch}/modules', '-framework', 'Foundation',
               '-lsqlite3', '-I', str(fmdb / 'include'), '-I', str(fmdb),
               '-I', str(ROOT / 'Chanify/Services'),
               str(ROOT / 'Chanify/Services/CHMessageSearch.m'),
               str(ROOT / ('Tests/Search/benchmark.m' if '--benchmark' in sys.argv else 'Tests/Search/main.m'))]
    command += [str(path) for path in sorted(fmdb.glob('*.m'))]
    command += ['-o', f'{scratch}/search-tests']
    subprocess.run(command, env=os.environ, check=True)
    arguments = [arg for arg in sys.argv[1:] if arg != '--benchmark']
    subprocess.run([f'{scratch}/search-tests'] + arguments, check=True)
