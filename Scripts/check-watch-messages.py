#!/usr/bin/env python3
"""Exercise Watch storage queries and transactions with isolated SQLite files."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
tests = root / 'Tests/WatchMessages'
fmdb = root / 'Packages/ChanifyDependencies/Sources/FMDB'
with tempfile.TemporaryDirectory(prefix='chanify-watch-messages-') as scratch:
    command = ['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-fmodules',
               f'-fmodules-cache-path={scratch}/modules', '-framework', 'Foundation',
               '-lsqlite3', '-Wno-incomplete-implementation', '-include', str(tests / 'Prefix.h')]
    for directory in [fmdb / 'include', fmdb, root / 'Chanify/Services', root / 'Chanify/Models',
                      root / 'Chanify/Security', root / 'Chanify/Extensions']:
        command += ['-I', str(directory)]
    command += [str(root / 'Chanify/Services/CHUserDataSource.m'),
                str(root / 'Chanify/Services/CHNSDataSource.m'), str(tests / 'main.m')]
    command += [str(path) for path in sorted(fmdb.glob('*.m'))]
    command += ['-o', f'{scratch}/watch-message-tests']
    subprocess.run(command, check=True)
    subprocess.run([f'{scratch}/watch-message-tests', scratch], check=True)
