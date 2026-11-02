// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_audio_toolkit",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "flutter-audio-toolkit", targets: ["flutter_audio_toolkit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_audio_toolkit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Accelerate")
            ]
        )
    ]
)
