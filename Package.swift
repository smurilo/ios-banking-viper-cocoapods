// swift-tools-version:5.9
// Mirrors the UIKit-independent pods so domain, networking and VIPER presenters/interactors
// can be built and tested on any machine (including Linux CI) with `swift test`.
import PackageDescription

let package = Package(
    name: "BankModules",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "BankCore", targets: ["BankCore"]),
        .library(name: "BankNetworking", targets: ["BankNetworking"]),
    ],
    targets: [
        .target(name: "BankCore", path: "LocalPods/BankCore/Sources"),
        .target(name: "BankNetworking", dependencies: ["BankCore"], path: "LocalPods/BankNetworking/Sources"),
        .target(name: "BankDesignSystem", dependencies: ["BankCore"], path: "LocalPods/BankDesignSystem/Sources"),
        .target(name: "FeatureStatement", dependencies: ["BankCore", "BankNetworking", "BankDesignSystem"], path: "LocalPods/FeatureStatement/Sources"),
        .target(name: "FeatureTransfer", dependencies: ["BankCore", "BankNetworking", "BankDesignSystem"], path: "LocalPods/FeatureTransfer/Sources"),
        .testTarget(name: "BankCoreTests", dependencies: ["BankCore"], path: "LocalPods/BankCore/Tests"),
        .testTarget(name: "BankNetworkingTests", dependencies: ["BankNetworking"], path: "LocalPods/BankNetworking/Tests"),
        .testTarget(name: "FeatureStatementTests", dependencies: ["FeatureStatement"], path: "LocalPods/FeatureStatement/Tests"),
        .testTarget(name: "FeatureTransferTests", dependencies: ["FeatureTransfer"], path: "LocalPods/FeatureTransfer/Tests"),
    ]
)
