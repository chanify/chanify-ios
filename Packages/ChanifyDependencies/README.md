# Chanify dependencies

This local Swift package replaces CocoaPods for every application and extension
in `Chanify.xcodeproj`. Open `Chanify.xcworkspace` in Xcode; there is no dependency
download or Ruby setup. FMDB, JLRoutes and Masonry retain the versions from the former lockfile;
Protobuf is upgraded to match the installed compiler:

| Product | Version | Upstream |
| --- | --- | --- |
| FMDB | 2.7.12 | https://github.com/ccgus/fmdb |
| JLRoutes | 2.1 | https://github.com/joeldev/JLRoutes |
| Masonry | 1.1.0 | https://github.com/SnapKit/Masonry |
| Protobuf (Objective-C runtime) | 5.36.2 (upstream v36.2) | https://github.com/protocolbuffers/protobuf |

FMDB, JLRoutes and Masonry were copied unchanged from the locked installation.
Protobuf Objective-C sources are copied unchanged from the official v36.2 release:
https://github.com/protocolbuffers/protobuf/releases/download/v36.2/protobuf-36.2.tar.gz
Archive SHA-256: `3d9642a662d10e68ebae5e53f14dcce5105684212d5078f8e0d47d1ab3ae6b64`.
Only top-level Objective-C headers and implementations are included, excluding
`GPBProtocolBuffers.m` (the amalgamation would duplicate the separately compiled
implementations). Optional Swift unknown-field convenience extensions are not
included in this Objective-C runtime target; Chanify does not use them.
`SOURCE-SHA256.json` records their checksums. Header symlinks under each target's
`include/<Product>/` preserve existing namespaced Objective-C imports. FMDB and
Protobuf privacy manifests are bundled as Swift package resources. FMDB links
system SQLite. FMDB, JLRoutes, and Masonry use ARC; Protobuf uses manual reference
counting. The application project preserves `-ObjC` to load Objective-C categories.
The package's compiler flags are intended for this local application dependency,
not distribution as a remote package with unsafe flags.

## Protobuf generation

The existing Xcode build rules generate `CHTP.pbobjc.h` and `CHTP.pbobjc.m` from
`Chanify/Models/CHTP.proto` in the derived-file directory, with ARC disabled for
the generated implementation. Generated sources are not edited or checked in.
Install the upstream **protoc 36.2** compiler and make it available to Xcode on
`PATH` (the script also checks the standard Homebrew locations), or set the
Xcode build setting `PROTOC` to its absolute path. Obtain it
from https://github.com/protocolbuffers/protobuf/releases/tag/v36.2 .
The Objective-C runtime version `5.36.2` corresponds to compiler release `36.2`.
Upgrade the compiler and runtime together and validate message serialization.

## Licenses and updates

Licenses are preserved in `Licenses/`. Run:

```sh
python3 Scripts/generate-acknowledgements.py
```

from the repository root after updating dependencies. Both generated plist files
are checked in, so a clean checkout includes the acknowledgements UI resources.
When updating a library, verify its provenance, replace its source and license,
refresh the header symlinks and checksums, regenerate acknowledgements, and check
all consuming targets, including macOS and watchOS. Do not hand-edit vendored
sources to resolve application compatibility issues.

## Validation

Run `python3 Scripts/check-dependencies.py` from the repository root on macOS
with Xcode selected (or `DEVELOPER_DIR` set). This builds the four packages and
checks namespaced header imports, SQLite read/write, URL routing, Objective-C
category loading, a Protobuf serialization roundtrip, and generated CHTP messages
against fixed wire-format fixtures (channel, text, unknown fields, negative enums,
and a nested Watch configuration).

The package and application now require iOS 15 / macOS 12, following the
upstream Objective-C runtime's supported deployment targets. The Watch app, its notification service, and this package require watchOS 9
because the Xcode 27.2 SDK no longer accepts older deployment targets. Full application and extension
builds must also be checked in Xcode.

Validation with protoc 36.2 and Xcode 27.2 passed for macOS, iOS arm64 (15.0),
and the watchOS runtime arm64_32 (9.0). The macOS integration checks also passed.
An Xcode MCP build of the iOS scheme passed on the iPhone 17 simulator
(iOS 27.2), including its bundled extensions and Watch targets. This verifies
compilation and linking, not runtime behavior. The macOS scheme still fails to
link because `CHFormOption` and `CHScriptViewController` implementations are
missing from that target; macOS application build validation remains incomplete.
