#!/usr/bin/env python3
"""Exercise production notification delivery with an isolated notification center."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
tests = root / 'Tests/WatchNotifications'
with tempfile.TemporaryDirectory(prefix='chanify-watch-notifications-') as scratch:
    for watch in (1, 0):
        executable = f'{scratch}/notifications-{watch}'
        command = ['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-fmodules',
                   f'-fmodules-cache-path={scratch}/modules', '-framework', 'Foundation',
                   '-framework', 'UserNotifications', '-Wno-incomplete-implementation',
                   f'-DCH_TEST_WATCH={watch}', '-include', str(tests / 'Prefix.h')]
        for directory in ['Chanify/Services', 'Chanify/Models', 'Chanify/Security', 'Chanify/Extensions']:
            command += ['-I', str(root / directory)]
        command += [str(root / 'Chanify/Services/CHNotification.m'), str(tests / 'main.m'), '-o', executable]
        subprocess.run(command, check=True)
        subprocess.run([executable], check=True)
