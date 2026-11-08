#!/usr/bin/env python3
"""Build local packages on macOS and exercise their Objective-C integration."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PRODUCTS = ('FMDB', 'JLRoutes', 'Masonry', 'Protobuf')
with tempfile.TemporaryDirectory(prefix='chanify-dependencies-') as scratch:
    environment = dict(os.environ, CLANG_MODULE_CACHE_PATH=f'{scratch}/modules')
    command = ['xcrun', 'swift', 'build', '--disable-sandbox',
               '--package-path', str(ROOT / 'Packages/ChanifyDependencies'),
               '--scratch-path', f'{scratch}/build']
    subprocess.run(command, env=environment, check=True)
    products = Path(subprocess.check_output(command + ['--show-bin-path'],
                                           env=environment, text=True).strip())
    sdk = subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'],
                                  env=environment, text=True).strip()
    generated = Path(scratch) / 'generated'
    generated.mkdir()
    generation_environment = dict(environment,
        INPUT_FILE_DIR=str(ROOT / 'Chanify/Models'),
        INPUT_FILE_PATH=str(ROOT / 'Chanify/Models/CHTP.proto'),
        DERIVED_FILE_DIR=str(generated))
    subprocess.run(['sh', str(ROOT / 'Scripts/generate-protobuf.sh')],
                   env=generation_environment, check=True)
    compiler = ['xcrun', 'clang', '-fobjc-arc', '-fmodules',
                f'-fmodules-cache-path={scratch}/modules', '-isysroot', sdk,
                '-ObjC']
    for name in PRODUCTS:
        compiler += ['-I', str(ROOT / f'Packages/ChanifyDependencies/Sources/{name}/include')]
    compiler += ['-DGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1', '-I', str(generated)]
    generated_object = str(generated / 'CHTP.o')
    # protoc's Objective-C implementations require manual reference counting.
    subprocess.run(compiler + ['-fno-objc-arc', '-c',
                   str(next(generated.glob('*.pbobjc.m'))), '-o', generated_object],
                   env=environment, check=True)
    compiler += ['-framework', 'Foundation', '-framework', 'AppKit', '-lsqlite3',
                 str(ROOT / 'Tests/Dependencies/main.m'), generated_object]
    for name in PRODUCTS:
        library = products / f'lib{name}.a'
        if library.exists():
            compiler.append(str(library))
        else:
            # Native SwiftPM emits object files for automatic library products.
            objects = list(products.glob(f'{name}.build/**/*.o'))
            if not objects:
                raise RuntimeError(f'Missing build outputs for {name}')
            compiler += [str(path) for path in objects]
    executable = f'{scratch}/dependency-smoke'
    subprocess.run(compiler + ['-o', executable], env=environment, check=True)
    subprocess.run([executable], env=environment, check=True)
