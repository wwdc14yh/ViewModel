// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "ViewModel",
                      platforms: [
                          .iOS(.v13),
                          .macOS(.v10_15),
                          .tvOS(.v13),
                          .watchOS(.v6),
                      ],
                      products: [
                          // Products define the executables and libraries a package produces, making them visible to other packages.
                          .library(name: "ViewModel",
                                   targets: ["ViewModel"]),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/wwdc14yh/ObservableObjectExtensions.git", .upToNextMajor(from: "0.0.1")),
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package, defining a module or a test suite.
                          // Targets can depend on other targets in this package and products from dependencies.
                          .target(name: "ViewModel",
                                  dependencies: [.product(name: "ObservableObjectExtensions", package: "ObservableObjectExtensions")]),
                      ])
