// swift-tools-version:4.0
import PackageDescription


let package = Package(
  name: "querykit",
  products: [
    .executable(name: "querykit", targets: ["querykit-cli"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kylef/Stencil.git", from: "0.9.0"),
    .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1"),
  ],
  targets: [
    .target(name: "querykit-cli", dependencies: ["Stencil", "Commander"]),
  ]
)
