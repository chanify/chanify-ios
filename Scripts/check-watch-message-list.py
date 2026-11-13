#!/usr/bin/env python3
"""Compile the complete production Watch model with isolated service substitutes."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
tests = root / 'Tests/WatchMessageList'
with tempfile.TemporaryDirectory(prefix='chanify-watch-list-') as scratch:
    env = dict(os.environ, CLANG_MODULE_CACHE_PATH=f'{scratch}/clang')
    command = ['xcrun', 'swiftc', '-swift-version', '5', '-module-cache-path', f'{scratch}/modules',
               str(tests / 'Stubs.swift'), str(root / 'Watch Extension/Models/LogicModel.swift'),
               str(tests / 'main.swift'), '-o', f'{scratch}/watch-list-tests']
    subprocess.run(command, env=env, check=True)
    subprocess.run([f'{scratch}/watch-list-tests'], check=True)
