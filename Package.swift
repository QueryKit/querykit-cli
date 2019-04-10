// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "querykit",
    dependencies: [
        .package(url: "https://github.com/kylef/Stencil.git",from: "0.13.0"),
        .package(url: "https://github.com/kylef/Commander.git",  from: "0.8.0")
    ],
    targets: [
        .target(
            name: "QueryKit",
            dependencies: ["Stencil", "Commander"],
            path: "Sources"
        )
    ]
)
