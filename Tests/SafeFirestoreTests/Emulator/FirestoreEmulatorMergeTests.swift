import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func mergePreservesFieldsThatAreNotWritten() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("merge-preserves-\(UUID().uuidString)")

    let initial = EmulatorUser(
      displayName: "Initial",
      score: 1,
      active: true,
      labels: ["kept"],
      profile: nil
    )

    try await reference.setData(from: initial)
    try await reference.setData(
      [.init(\.displayName, "Updated")],
      merge: true
    )

    let decoded = try await reference.getDataDocument()

    #expect(decoded.displayName == "Updated")
    #expect(decoded.score == 1)
    #expect(decoded.active)
    #expect(decoded.labels == ["kept"])
  }

  @Test
  func verifiesSelectedMergeFieldsOnANewDocument() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("merge-fields-partial-\(UUID().uuidString)")

    let model = EmulatorUser(
      displayName: "Selected",
      score: 7,
      active: true,
      labels: ["not-written"],
      profile: nil
    )

    try await reference.setData(
      from: model,
      mergeFields: [
        .init(\.displayName),
        .init(\.score)
      ]
    )

    let snapshot = try await reference.getDocument()
    let rawData = snapshot._documentSnapshot.data() ?? [:]

    #expect(Set(rawData.keys) == ["displayName", "score"])
    #expect(rawData["displayName"] as? String == "Selected")
    #expect(rawData["score"] as? Int == 7)
  }

  @Test
  func verifiesUpdateRejectsMissingDocument() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("update-missing-\(UUID().uuidString)")

    var didThrow = false

    do {
      try await reference.updateData([.init(\.score, 10)])
    } catch {
      didThrow = true
    }

    #expect(didThrow)
  }

  @Test
  func verifiesDeleteRemovesDocument() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("delete-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "To delete",
      score: 1,
      active: false,
      labels: [],
      profile: nil
    ))

    try await reference.delete()

    let snapshot = try await reference.getDocument()
    #expect(!snapshot.exists)
  }
}
