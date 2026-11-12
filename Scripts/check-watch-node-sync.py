#!/usr/bin/env python3
"""Run production Watch node synchronization with isolated, mocked platform/transport services."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
tests = root / 'Tests/WatchNodeSync'
with tempfile.TemporaryDirectory(prefix='chanify-watch-sync-') as scratch:
    command = ['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-fmodules',
               f'-fmodules-cache-path={scratch}/modules', '-framework', 'Foundation',
               '-Wno-incomplete-implementation', '-include', str(tests / 'Prefix.h')]
    for directory in [tests / 'Stubs', root / 'Watch Extension/Services',
                      root / 'Chanify/Services', root / 'Chanify/Models',
                      root / 'Chanify/Security', root / 'Chanify/Extensions']:
        command += ['-I', str(directory)]
    command += [str(root / 'Watch Extension/Services/CHLogic+watchOS.m'),
                str(root / 'Chanify/Models/CHNodeModel.m'), str(tests / 'main.m'),
                '-o', f'{scratch}/watch-sync-tests']
    subprocess.run(command, check=True)
    subprocess.run([f'{scratch}/watch-sync-tests'], check=True)
