// swift-tools-version: 5.9
import PackageDescription

// Versions and upstream provenance are recorded in README.md.
let package = Package(
    name: "ChanifyDependencies",
    platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v9)],
    products: [
        .library(name: "FMDB", targets: ["FMDB"]),
        .library(name: "JLRoutes", targets: ["JLRoutes"]),
        .library(name: "Masonry", targets: ["Masonry"]),
        .library(name: "Protobuf", targets: ["Protobuf"]),
    ],
    targets: [
        .target(
            name: "FMDB",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .unsafeFlags(["-fobjc-arc"]),
            ],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .target(
            name: "JLRoutes",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Classes"),
                .unsafeFlags(["-fobjc-arc"]),
            ]
        ),
        .target(
            name: "Masonry",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .unsafeFlags(["-fobjc-arc"]),
            ]
        ),
        .target(
            name: "Protobuf",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS", to: "1"),
                .unsafeFlags(["-fno-objc-arc"]),
            ]
        ),
    ]
)
