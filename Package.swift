import PackageDescription


let package = Package(
  name: "querykit",
  dependencies: [
    .Package(url: "https://github.com/kylef/Stencil.git", majorVersion: 0, minor: 9),
    .Package(url: "https://github.com/kylef/Commander.git", majorVersion: 0, minor: 6),
  ]
)
