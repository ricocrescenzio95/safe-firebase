import Testing
import SafeFirestore
import Foundation

extension FirestoreEmulatorTests {
  @Test
  func failedBatchIsAtomic() async throws {
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

    let unchanged = try await existing.getDataDocument()
    let missingSnapshot = try await missing.getDocument()

    #expect(unchanged.score == 10)
    #expect(!missingSnapshot.exists)
  }

  @Test
  func batchCanCreateUpdateAndDeleteDocumentsAtomically() async throws {
    let created = firestore
      .collection(EmulatorUser.self)
      .document("batch-created-\(UUID().uuidString)")
    let updated = firestore
      .collection(EmulatorUser.self)
      .document("batch-updated-\(UUID().uuidString)")
    let deleted = firestore
      .collection(EmulatorUser.self)
      .document("batch-deleted-\(UUID().uuidString)")

    try await deleted.setData(from: EmulatorUser(
      displayName: "Delete",
      score: 1,
      active: false,
      labels: [],
      profile: nil
    ))
    try await updated.setData(from: EmulatorUser(
      displayName: "Before",
      score: 1,
      active: false,
      labels: [],
      profile: nil
    ))

    let batch = firestore.typedBatch()
    try batch.setData(
      from: EmulatorUser(
        displayName: "Created",
        score: 3,
        active: true,
        labels: ["created"],
        profile: nil
      ),
      forDocument: created
    )
    batch.updateData([.init(\.displayName, "Updated")], forDocument: updated)
    batch.deleteDocument(deleted)

    try await batch.commit()

    #expect((try await created.getDataDocument()).displayName == "Created")
    #expect((try await updated.getDataDocument()).displayName == "Updated")
    #expect(!(try await deleted.getDocument()).exists)
  }
}
