// swift-tools-version: 6.4

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "safe-firebase",
  platforms: [.iOS(.v15), .macCatalyst(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v9)],
  products: [
    .library(.safeFirestore),
  ],
  dependencies: [.swiftSyntax, .firebase],
  targets: [
    .safeFirebaseMacros,
    .safeFirebaseMacrosTests,
    
    .safeFirestore,
    .safeFirestoreTests
  ]
)

// MARK: - Libs

extension Target {
  static var safeFirestore: Target {
    .target(
      name: "SafeFirestore",
      dependencies: [.firestore, .target(.safeFirebaseMacros)],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ],
    )
  }
  static var safeFirestoreTests: Target {
    .testTarget(
      name: "SafeFirestoreTests",
      dependencies: ["SafeFirestore", .firebaseCore],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ],
    )
  }
}

// MARK: - Package dependencies
extension Package.Dependency {
  static var swiftSyntax: Package.Dependency {
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git",
      "600.0.0"..<"605.0.0"
    )
  }
  static var firebase: Package.Dependency {
    .package(
      url: "https://github.com/firebase/firebase-ios-sdk.git",
      from: "12.0.0"
    )
  }
}

// MARK: - Target dependencies
extension Target.Dependency {
  static let swiftSyntaxMacrosTestSupport = Target.Dependency.product(
    name: "SwiftSyntaxMacrosTestSupport", package: .swiftSyntax
  )
  static let swiftCompilerPlugin = Target.Dependency.product(
    name: "SwiftCompilerPlugin", package: .swiftSyntax
  )
  static let swiftSyntaxMacros = Target.Dependency.product(
    name: "SwiftSyntaxMacros", package: .swiftSyntax
  )
  static let swiftSyntax = Target.Dependency.product(name: "SwiftSyntax", package: .swiftSyntax)
  static let swiftSyntaxBuilder = Target.Dependency.product(name: "SwiftSyntaxBuilder", package: .swiftSyntax)
  static let swiftDiagnostics = Target.Dependency.product(name: "SwiftDiagnostics", package: .swiftSyntax)
  static let swiftParser = Target.Dependency.product(
      name: "SwiftParser",
      package: .swiftSyntax
  )
  
  static let firestore = Target.Dependency.product(name: "FirebaseFirestore", package: .firebase)
  static let firebaseCore = Target.Dependency.product(name: "FirebaseCore", package: .firebase)
  static let database = Target.Dependency.product(name: "FirebaseDatabase", package: .firebase)
  static let functions = Target.Dependency.product(name: "FirebaseFunctions", package: .firebase)
}

// MARK: - Macros
extension Target {
  static var safeFirebaseMacros: Target {
    .macro(
      name: "SafeFirebaseMacros",
      dependencies: [
        .swiftSyntaxMacros,
        .swiftCompilerPlugin,
        .swiftSyntax,
        .swiftSyntaxBuilder,
        .swiftDiagnostics,
        .swiftParser,
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ],
    )
  }
  static var safeFirebaseMacrosTests: Target {
    .testTarget(
      name: "SafeFirebaseMacrosTests",
      dependencies: [.target(.safeFirebaseMacros), .swiftSyntaxMacrosTestSupport],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ],
    )
  }
}

// MARK: - Extensions

extension Target.Dependency {
  static func target(_ target: Target) -> Target.Dependency {
    .byName(name: target.name)
  }
  
  static func product(name: String, package: Package.Dependency) -> Target.Dependency {
    switch package.kind {
    case .sourceControl(_, let url, _):
      .product(name: name, package: url.split(separator: "/").last.map { String($0).replacing(".git", with: "") } ?? "")
    case .fileSystem(let packageName, _):
      .product(name: name, package: packageName ?? "")
    case .registry(let id, _):
      .product(name: name, package: id)
    @unknown default:
      .product(name: name, package: "")
    }
  }
}

extension Product {
  static func library(_ target: Target, type: Library.LibraryType? = nil) -> Product {
    .library(name: target.name, type: type, targets: [target.name])
  }
  
  static func plugin(_ target: Target) -> Product {
    .plugin(name: target.name, targets: [target.name])
  }
}
