// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "HexisMD",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/textual", exact: "0.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "HexisMD",
            dependencies: [
                .product(name: "Textual", package: "textual"),
            ],
            path: "Sources/HexisMD"
        )
    ]
)
