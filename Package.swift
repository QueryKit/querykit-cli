// swift-tools-version:4.0
import PackageDescription


let package = Package(
  name: "querykit",
  products: [
    .executable(name: "querykit", targets: ["querykit-cli"]),
  ],
  dependencies: [
    .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.13.1"),
    .package(url: "https://github.com/kylef/Commander.git", from: "0.9.1"),
  ],
  targets: [
    .target(name: "querykit-cli", dependencies: ["Stencil", "Commander"]),
  ]
)
