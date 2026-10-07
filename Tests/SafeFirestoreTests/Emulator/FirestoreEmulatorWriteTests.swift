import Foundation
import Testing
@preconcurrency import FirebaseFirestore
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func mergesAndUpdatesSelectedFields() async throws {
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
  }

  @Test
  func writesPartialDataWithMergeFields() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("merge-fields-\(UUID().uuidString)")

    let initialUser = EmulatorUser(
      displayName: "Merge fields",
      score: 7,
      active: true,
      labels: ["partial"],
      profile: nil
    )
    try await reference.setData(from: initialUser)

    let user = EmulatorUser(
      displayName: "New Merge fields",
      score: 10,
      active: false,
      labels: ["partial", "second partial"],
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
    #expect(decoded.displayName == "New Merge fields")
    #expect(decoded.score == 10)
    #expect(decoded.active)
    #expect(decoded.labels == ["partial"])
    #expect(decoded.profile == nil)
  }

  @Test
  func mergeFieldsWritesOnlyTheSelectedFieldsOnANewDocument() async throws {
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
  func updateFailsForANonExistingDocument() async throws {
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
  func deleteRemovesAnExistingDocument() async throws {
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

  @Test
  func failedBatchDoesNotApplyAnyWrite() async throws {
    let existing = firestore
      .collection(EmulatorUser.self)
      .document("batch-existing-\(UUID().uuidString)")
    let missing = firestore
      .collection(EmulatorUser.self)
      .document("batch-missing-\(UUID().uuidString)")

    try await existing.setData(from: EmulatorUser(
      displayName: "Before",
      score: 10,
      active: false,
      labels: ["before"],
      profile: nil
    ))

    let batch = firestore.typedBatch()
    batch.updateData([.init(\.score, 99)], forDocument: existing)
    batch.updateData([.init(\.score, 42)], forDocument: missing)

    var didThrow = false
    do {
      try await batch.commit()
    } catch {
      didThrow = true
    }

    #expect(didThrow)
    #expect((try await existing.getDataDocument()).score == 10)
    #expect(!(try await missing.getDocument()).exists)
  }

  @Test
  func typedWriteBatchCommitsMultipleOperations() async throws {
    let updatedReference = firestore.collection(EmulatorUser.self)
      .document("batch-updated-\(UUID().uuidString)")
    let createdReference = firestore.collection(EmulatorUser.self)
      .document("batch-created-\(UUID().uuidString)")
    let deletedReference = firestore.collection(EmulatorUser.self)
      .document("batch-deleted-\(UUID().uuidString)")

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
    batch.updateData(
      [
        .init(\.displayName, "After batch"),
        .init(\.score, 99),
        .init(\.active, true)
      ],
      forDocument: updatedReference
    )
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
  }
}
