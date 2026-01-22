// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MercurioiOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MercurioiOS",
            targets: ["MercurioiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        .package(url: "https://github.com/ionspin/swift-bip39.git", from: "1.0.0"),
        .package(url: "https://github.com/mattmassicotte/ConcurrentCoreData.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MercurioiOS",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "BIP39", package: "swift-bip39")
            ],
            path: "Sources"
        )
    ]
)
