import Foundation
import Testing
import FirebaseCore
@preconcurrency import FirebaseFirestore
import SafeFirestore

@FirestoreCollection("emulator-users")
struct EmulatorUser {
  var displayName: String
  var score: Int
  var active: Bool
  var labels: [String]
  var profile: EmulatorProfile?
}

@FirestoreModel
struct EmulatorProfile {
  var city: String
  var visits: Int64
}

private let projectID = "demo-safe-firebase"

@Suite(.serialized)
struct FirestoreEmulatorTests {
  var firestore: Firestore { Self.firestore }

  init() async throws {
    do {
      try await waitForFirestoreEmulator()
    } catch {
      try Test.cancel("Firestore Emulator not available: \(error)")
    }

    try await clearFirestoreEmulator(projectID: projectID)
  }

  private static let firestore: Firestore = {
    let options = FirebaseOptions(
      googleAppID: "1:1234567890:ios:1234567890abcdef1234567890abcdef",
      gcmSenderID: "1234567890"
    )
    options.projectID = projectID

    let app: FirebaseApp
    if let existing = FirebaseApp.app(name: "SafeFirebaseFirestoreEmulator") {
      app = existing
    } else {
      FirebaseApp.configure(
        name: "SafeFirebaseFirestoreEmulator",
        options: options
      )
      app = FirebaseApp.app(name: "SafeFirebaseFirestoreEmulator")!
    }

    let firestore = Firestore.firestore(app: app)
    let settings = FirestoreSettings()
    settings.cacheSettings = MemoryCacheSettings()
    settings.host = "127.0.0.1:8080"
    settings.isSSLEnabled = false
    firestore.settings = settings
    return firestore
  }()
}
