#!/bin/sh
# Called by Xcode's .proto build rules; PROTOC may be an absolute executable path.
set -eu
compiler=${PROTOC:-}
if [ -z "$compiler" ]; then
    compiler=$(command -v protoc || true)
    if [ -z "$compiler" ]; then
        # Xcode launched from Finder may not inherit Homebrew's PATH.
        for candidate in /opt/homebrew/bin/protoc /usr/local/bin/protoc; do
            if [ -x "$candidate" ]; then
                compiler=$candidate
                break
            fi
        done
    fi
fi
if ! command -v "$compiler" >/dev/null 2>&1; then
    echo "error: protoc 36.2 is required. Install it and set PROTOC to its executable path. See Packages/ChanifyDependencies/README.md." >&2
    exit 1
fi
version=$("$compiler" --version)
if [ "$version" != 'libprotoc 36.2' ]; then
    echo "error: Expected libprotoc 36.2 for the pinned Objective-C runtime, got $version." >&2
    exit 1
fi
exec "$compiler" --proto_path="$INPUT_FILE_DIR" --objc_out="$DERIVED_FILE_DIR" "$INPUT_FILE_PATH"
