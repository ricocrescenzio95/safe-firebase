import Foundation
import Testing
@preconcurrency import FirebaseFirestore
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func transactionSupportsModelFieldDataAndDeleteOverloads() async throws {
    let modelReference = firestore.collection(EmulatorUser.self)
      .document("transaction-model-\(UUID().uuidString)")
    let rawReference = firestore.collection(EmulatorUser.self)
      .document("transaction-raw-\(UUID().uuidString)")
    let fieldsReference = firestore.collection(EmulatorUser.self)
      .document("transaction-fields-\(UUID().uuidString)")
    let modelFieldsReference = firestore.collection(EmulatorUser.self)
      .document("transaction-model-fields-\(UUID().uuidString)")
    let modelCreateReference = firestore.collection(EmulatorUser.self)
      .document("transaction-model-create-\(UUID().uuidString)")
    let rawMergeReference = firestore.collection(EmulatorUser.self)
      .document("transaction-raw-merge-\(UUID().uuidString)")
    let deletedReference = firestore.collection(EmulatorUser.self)
      .document("transaction-delete-\(UUID().uuidString)")

    try await modelReference.setData(from: EmulatorUser(
      displayName: "Before", score: 1, active: false, labels: ["kept"], profile: nil
    ))
    try await deletedReference.setData(from: EmulatorUser(
      displayName: "Delete", score: 0, active: false, labels: [], profile: nil
    ))

    let model = EmulatorUser(
      displayName: "Model", score: 2, active: true, labels: ["model"], profile: nil
    )
    let raw: [DocumentData<EmulatorUser>] = [.init(\.displayName, "Raw"), .init(\.score, 3)]
    let mergeFields: [DocumentDataField<EmulatorUser>] = [.init(\.score)]

    let transactionResult = try await firestore.runTypedTransaction { transaction in
      try transaction.setData(from: model, forDocument: modelReference, merge: true)
      try transaction.setData(from: model, forDocument: modelCreateReference)
      try transaction.setData(
        from: model,
        forDocument: modelFieldsReference,
        mergeFields: [.init(\.score)]
      )
      transaction.setData(raw, forDocument: rawReference)
      transaction.setData(raw, forDocument: rawMergeReference, merge: true)
      transaction.setData(raw, forDocument: fieldsReference, mergeFields: mergeFields)
      transaction.updateData([.init(\.active, true)], forDocument: modelReference)
      transaction.deleteDocument(deletedReference)
      return true
    }
    
    #expect(transactionResult)

    let modelResult = try await modelReference.getDataDocument()
    let rawSnapshot = try await rawReference.getDocument()
    let fieldsSnapshot = try await fieldsReference.getDocument()
    let modelFieldsSnapshot = try await modelFieldsReference.getDocument()
    let modelCreateSnapshot = try await modelCreateReference.getDocument()
    let rawMergeSnapshot = try await rawMergeReference.getDocument()

    #expect(modelResult.displayName == "Model")
    #expect(modelResult.active)
    #expect(rawSnapshot._documentSnapshot.data()?["score"] as? Int == 3)
    #expect(fieldsSnapshot._documentSnapshot.data()?["score"] as? Int == 3)
    #expect(modelFieldsSnapshot._documentSnapshot.data()?["score"] as? Int == 2)
    #expect(modelFieldsSnapshot._documentSnapshot.data()?["displayName"] == nil)
    #expect(try modelCreateSnapshot.data().displayName == "Model")
    #expect(rawMergeSnapshot._documentSnapshot.data()?["score"] as? Int == 3)
    #expect(!(try await deletedReference.getDocument()).exists)
  }
}
