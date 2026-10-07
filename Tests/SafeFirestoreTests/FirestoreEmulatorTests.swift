import Foundation
import Testing
import FirebaseCore
import FirebaseFirestore
import SafeFirestore

private let firestoreEmulatorEnabled = ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_HOST"] != nil

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

struct FirestoreEmulatorTests {
  private static let projectID = "demo-safe-firebase"
  private static let appLock = NSLock()
  
  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func writesAndReadsTypedDocument() async throws {
    let firestore = Self.makeFirestore()
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("typed-read-\(UUID().uuidString)")
    
    let expected = EmulatorUser(
      displayName: "Ada",
      score: 42,
      active: true,
      labels: ["swift", "firebase"],
      profile: EmulatorProfile(city: "Rome", visits: 3)
    )
    
    try await reference.setData(from: expected)
    let actual = try await reference.getDataDocument()
    
    #expect(actual.displayName == expected.displayName)
    #expect(actual.score == expected.score)
    #expect(actual.active == expected.active)
    #expect(actual.labels == expected.labels)
    #expect(actual.profile?.city == "Rome")
    #expect(actual.profile?.visits == 3)
    
    try await reference.delete()
  }
  
  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func writesAndReadsTypedSnapshotMetadata() async throws {
    let firestore = Self.makeFirestore()
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("snapshot-\(UUID().uuidString)")
    
    try await reference.setData(from: EmulatorUser(
      displayName: "Grace",
      score: 90,
      active: true,
      labels: ["admin"],
      profile: nil
    ))
    
    let snapshot = try await reference.getDocument()
    
    #expect(snapshot.exists)
    #expect(snapshot.documentID == reference.documentID)
    #expect(snapshot.id == reference.documentID)
    #expect(snapshot.reference.path == reference.path)
    
    let decoded = try snapshot.data()
    #expect(decoded.displayName == "Grace")
    #expect(decoded.profile == nil)
    
    try await reference.delete()
  }
  
  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func queriesTypedDocumentsWithNestedPredicates() async throws {
    let firestore = Self.makeFirestore()
    let collection = firestore.collection(EmulatorUser.self)
    let prefix = "query-\(UUID().uuidString)"
    
    let matching = collection.document("\(prefix)-matching")
    let nonMatching = collection.document("\(prefix)-nonmatching")
    
    try await matching.setData(from: EmulatorUser(
      displayName: "Matching",
      score: 80,
      active: true,
      labels: ["swift"],
      profile: EmulatorProfile(city: "Milan", visits: 10)
    ))
    try await nonMatching.setData(from: EmulatorUser(
      displayName: "Non matching",
      score: 20,
      active: false,
      labels: ["other"],
      profile: EmulatorProfile(city: "Rome", visits: 1)
    ))
    
    let snapshot = try await collection
      .where { $0.score >= 50 && $0.active }
      .getDocuments()
    
    let users = try snapshot.documents.map { try $0.data() }
    let ids = Set(snapshot.documents.map(\.documentID))
    
    #expect(snapshot.count == 1)
    #expect(ids == [matching.documentID])
    #expect(users.first?.displayName == "Matching")
    #expect(users.first?.profile?.city == "Milan")
    
    try await matching.delete()
    try await nonMatching.delete()
  }
  
  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func mergesAndUpdatesSelectedFields() async throws {
    let firestore = Self.makeFirestore()
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("merge-\(UUID().uuidString)")
    
    try await reference.setData(from: EmulatorUser(
      displayName: "Initial",
      score: 10,
      active: false,
      labels: ["initial"],
      profile: nil
    ))
    
    try await reference.setData(
      [.init(\.displayName, "Updated")],
      merge: true
    )
    var user = try await reference.getDataDocument()
    #expect(user.displayName == "Updated")
    #expect(user.score == 10)
    
    try await reference.updateData([
      .init(\.score, 99),
      .init(\.active, true)
    ])
    user = try await reference.getDataDocument()
    
    #expect(user.displayName == "Updated")
    #expect(user.score == 99)
    #expect(user.active)
    
    try await reference.delete()
  }
  
  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func writesPartialDataWithMergeFields() async throws {
    let firestore = Self.makeFirestore()
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("merge-fields-\(UUID().uuidString)")
    let user = EmulatorUser(
      displayName: "Merge fields",
      score: 7,
      active: true,
      labels: ["partial"],
      profile: nil
    )
    
    try await reference.setData(
      from: user,
      mergeFields: [
        .init(\.displayName),
        .init(\.score)
      ]
    )
    
    let decoded = try await reference.getDataDocument()
    #expect(decoded.displayName == "Merge fields")
    #expect(decoded.score == 7)
    #expect(decoded.active == false)
    #expect(decoded.labels.isEmpty)
    #expect(decoded.profile == nil)
    
    try await reference.delete()
  }

  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func typedWriteBatchCommitsMultipleOperations() async throws {
    let firestore = Self.makeFirestore()
    let collection = firestore.collection(EmulatorUser.self)
    let updatedReference = collection.document("batch-updated-\(UUID().uuidString)")
    let createdReference = collection.document("batch-created-\(UUID().uuidString)")
    let deletedReference = collection.document("batch-deleted-\(UUID().uuidString)")

    try await deletedReference.setData(from: EmulatorUser(
      displayName: "To delete",
      score: 1,
      active: false,
      labels: [],
      profile: nil
    ))
    try await updatedReference.setData(from: EmulatorUser(
      displayName: "Before batch",
      score: 10,
      active: false,
      labels: ["before"],
      profile: nil
    ))

    let batch = firestore.typedBatch()
    batch.updateData([
      .init(\.displayName, "After batch"),
      .init(\.score, 99),
      .init(\.active, true)
    ], forDocument: updatedReference)
    try batch.setData(
      from: EmulatorUser(
        displayName: "Created in batch",
        score: 7,
        active: true,
        labels: ["batch"],
        profile: nil
      ),
      forDocument: createdReference
    )
    batch.deleteDocument(deletedReference)
    try await batch.commit()

    let updated = try await updatedReference.getDataDocument()
    let created = try await createdReference.getDataDocument()
    let deletedSnapshot = try await deletedReference.getDocument()

    #expect(updated.displayName == "After batch")
    #expect(updated.score == 99)
    #expect(updated.active)
    #expect(created.displayName == "Created in batch")
    #expect(created.labels == ["batch"])
    #expect(!deletedSnapshot.exists)

    try await updatedReference.delete()
    try await createdReference.delete()
  }

  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func typedTransactionReadsAndReturnsAValueAfterUpdating() async throws {
    let firestore = Self.makeFirestore()
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("transaction-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "Transaction",
      score: 10,
      active: false,
      labels: ["initial"],
      profile: nil
    ))

    let nextScore: Int = try await firestore.runTypedTransaction { transaction in
      let snapshot = try transaction.getDocument(reference)
      let current = try snapshot.data()
      let next = current.score + 5
      transaction.updateData([
        .init(\.score, next),
        .init(\.active, true)
      ], forDocument: reference)
      return next
    }

    let updated = try await reference.getDataDocument()
    #expect(nextScore == 15)
    #expect(updated.score == 15)
    #expect(updated.active)

    try await reference.delete()
  }

  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func typedAggregateQueryReturnsTheDocumentCount() async throws {
    let firestore = Self.makeFirestore()
    let collection = firestore.collection(EmulatorUser.self)
    let first = collection.document("aggregate-first-\(UUID().uuidString)")
    let second = collection.document("aggregate-second-\(UUID().uuidString)")

    let model = EmulatorUser(
      displayName: "Aggregate",
      score: 1,
      active: true,
      labels: [],
      profile: nil
    )
    try await first.setData(from: model)
    try await second.setData(from: model)

    let aggregate = try await collection
      .where { $0.active == true }
      .count
      .getAggregation()

    #expect(aggregate.count == 2)

    try await first.delete()
    try await second.delete()
  }

  @Test(.enabled(if: firestoreEmulatorEnabled, "Set FIRESTORE_EMULATOR_HOST to run Firestore Emulator tests"))
  func typedAggregateQueryDecodesTypedSumAndAverage() async throws {
    let firestore = Self.makeFirestore()
    let collection = firestore.collection(EmulatorUser.self)
    let first = collection.document("aggregate-sum-first-\\(UUID().uuidString)")
    let second = collection.document("aggregate-sum-second-\\(UUID().uuidString)")

    try await first.setData(from: EmulatorUser(
      displayName: "First",
      score: 2,
      active: true,
      labels: [],
      profile: nil
    ))
    try await second.setData(from: EmulatorUser(
      displayName: "Second",
      score: 4,
      active: true,
      labels: [],
      profile: nil
    ))

    let result = try await collection
      .aggregate([
        .sum(\.score),
        .average(\.score)
      ])
      .getAggregation()

    let total: Int? = result.get(.sum(\.score))
    let average: Double? = result.get(.average(\.score))

    #expect(total == 6)
    #expect(average == 3)

    try await first.delete()
    try await second.delete()
  }

  private static func makeFirestore() -> Firestore {
    appLock.lock()
    defer { appLock.unlock() }
    
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
    settings.host = ProcessInfo.processInfo.environment["FIRESTORE_EMULATOR_HOST"] ?? "127.0.0.1:8080"
    settings.isSSLEnabled = false
    firestore.settings = settings
    return firestore
  }
}
