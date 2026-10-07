import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func writesAndReadsTypedDocument() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("typed-read-\(UUID().uuidString)")

    let expected = EmulatorUser(
      displayName: "Ada", score: 42, active: true,
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
  }

  @Test
  func writesAndReadsTypedSnapshotMetadata() async throws {
    let reference = firestore.collection(EmulatorUser.self)
      .document("snapshot-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "Grace", score: 90, active: true,
      labels: ["admin"], profile: nil
    ))

    let snapshot = try await reference.getDocument()
    #expect(snapshot.exists)
    #expect(snapshot.documentID == reference.documentID)
    #expect(snapshot.id == reference.documentID)
    #expect(snapshot.reference.path == reference.path)

    let decoded = try snapshot.data()
    #expect(decoded.displayName == "Grace")
    #expect(decoded.profile == nil)
  }
}
