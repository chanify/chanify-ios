#!/usr/bin/env python3
"""Exercise production token generation with real protobuf and synthetic identity/key storage."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='chanify-server-token-') as scratch:
    env = dict(os.environ, CLANG_MODULE_CACHE_PATH=f'{scratch}/modules')
    package = root / 'Packages/ChanifyDependencies'
    build = ['xcrun', 'swift', 'build', '--disable-sandbox', '--package-path', str(package),
             '--scratch-path', f'{scratch}/build', '--target', 'Protobuf']
    subprocess.run(build, env=env, check=True)
    subprocess.run(['sh', str(root / 'scripts/generate-protobuf.sh')], check=True, env=dict(env,
        INPUT_FILE_DIR=str(root / 'Chanify/Models'), INPUT_FILE_PATH=str(root / 'Chanify/Models/CHTP.proto'),
        DERIVED_FILE_DIR=scratch))
    compiler = ['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-fmodules',
                f'-fmodules-cache-path={scratch}/modules', '-DGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
                '-Wno-incomplete-implementation', '-include', str(root / 'Tests/ServerToken/Prefix.h')]
    for path in ['Tests/ServerToken/Stubs', 'Chanify/Models', 'Chanify/Security', 'Chanify/Extensions',
                 'Packages/ChanifyDependencies/Sources/Protobuf/include']:
        compiler += ['-I', str(root / path)]
    compiler += ['-I', scratch]
    subprocess.run(compiler + ['-fno-objc-arc', '-c', f'{scratch}/CHTP.pbobjc.m', '-o', f'{scratch}/CHTP.o'], env=env, check=True)
    sources = ['Chanify/Models/CHToken.m', 'Chanify/Models/CHNodeModel.m',
               'Chanify/Security/CHCrpyto.m', 'Chanify/Extensions/NSData+CHExt.m', 'Tests/ServerToken/main.m']
    objects = list(Path(scratch, 'build').rglob('*.o'))
    objects = [p for p in objects if 'Protobuf' in str(p) and 'Products' not in p.parts]
    if not objects:
        raise RuntimeError('Missing Protobuf build objects')
    subprocess.run(compiler + ['-framework', 'Foundation', '-ObjC'] + [str(root / p) for p in sources]
                   + [f'{scratch}/CHTP.o'] + [str(p) for p in objects] + ['-o', f'{scratch}/test'], env=env, check=True)
    subprocess.run([f'{scratch}/test'], check=True)
