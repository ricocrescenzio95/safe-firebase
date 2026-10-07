import Foundation
import Testing
@preconcurrency import FirebaseFirestore
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func batchSupportsModelAndFieldDataOverloads() async throws {
    let modelReference = firestore.collection(EmulatorUser.self)
      .document("batch-model-\(UUID().uuidString)")
    let rawReference = firestore.collection(EmulatorUser.self)
      .document("batch-raw-\(UUID().uuidString)")
    let fieldsReference = firestore.collection(EmulatorUser.self)
      .document("batch-fields-\(UUID().uuidString)")
    let modelFieldsReference = firestore.collection(EmulatorUser.self)
      .document("batch-model-fields-\(UUID().uuidString)")
    let deletedReference = firestore.collection(EmulatorUser.self)
      .document("batch-delete-\(UUID().uuidString)")

    try await deletedReference.setData(from: EmulatorUser(
      displayName: "Delete", score: 0, active: false, labels: [], profile: nil
    ))
    try await modelReference.setData(from: EmulatorUser(
      displayName: "Before", score: 1, active: false, labels: ["kept"], profile: nil
    ))

    let model = EmulatorUser(
      displayName: "Model", score: 2, active: true, labels: ["model"], profile: nil
    )
    let raw: [DocumentData<EmulatorUser>] = [.init(\.displayName, "Raw"), .init(\.score, 3)]
    let mergeRaw: [DocumentData<EmulatorUser>] = [.init(\.score, 4)]
    let mergeFields: [DocumentDataField<EmulatorUser>] = [.init(\.score)]

    let batch = firestore.typedBatch()
    try batch.setData(from: model, forDocument: modelReference, merge: true)
    batch.setData(raw, forDocument: rawReference)
    batch.setData(mergeRaw, forDocument: modelReference, merge: true)
    batch.setData(raw, forDocument: fieldsReference, mergeFields: mergeFields)
    try batch.setData(from: model, forDocument: modelFieldsReference, mergeFields: mergeFields)
    batch.updateData([.init(\.active, true)], forDocument: modelReference)
    batch.deleteDocument(deletedReference)
    try await batch.commit()

    let modelResult = try await modelReference.getDataDocument()
    let rawSnapshot = try await rawReference.getDocument()
    let fieldsSnapshot = try await fieldsReference.getDocument()
    let modelFieldsSnapshot = try await modelFieldsReference.getDocument()

    #expect(modelResult.displayName == "Model")
    #expect(modelResult.score == 4)
    #expect(modelResult.active)
    #expect(rawSnapshot._documentSnapshot.data()?["displayName"] as? String == "Raw")
    #expect(fieldsSnapshot._documentSnapshot.data()?["score"] as? Int == 3)
    #expect(modelFieldsSnapshot._documentSnapshot.data()?["score"] as? Int == 2)
    #expect(modelFieldsSnapshot._documentSnapshot.data()?["displayName"] == nil)
    #expect(!(try await deletedReference.getDocument()).exists)
  }
}
