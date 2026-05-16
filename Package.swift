// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceTyper",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "VoiceTyper"
        )
    ]
)
