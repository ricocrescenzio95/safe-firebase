import Foundation
import Testing
@preconcurrency import FirebaseFirestore
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func decodingFailsWhenRequiredFirestoreFieldIsMissing() async throws {
    let document = firestore
      .collection("emulator-users")
      .document("missing-required-\(UUID().uuidString)")

    try await document.setData([
      "displayName": "Partial",
      "score": 7,
      "labels": ["partial"]
    ])

    var didThrowDecodingError = false

    do {
      _ = try await firestore
        .collection(EmulatorUser.self)
        .document(document.documentID)
        .getDataDocument()
    } catch is DecodingError {
      didThrowDecodingError = true
    }

    #expect(didThrowDecodingError)
  }

  @Test
  func decodingFailsWhenFirestoreFieldHasAnIncompatibleType() async throws {
    let document = firestore
      .collection("emulator-users")
      .document("wrong-type-\(UUID().uuidString)")

    try await document.setData([
      "displayName": "Wrong type",
      "score": "not-an-integer",
      "active": true,
      "labels": []
    ])

    var didThrowDecodingError = false

    do {
      _ = try await firestore
        .collection(EmulatorUser.self)
        .document(document.documentID)
        .getDataDocument()
    } catch is DecodingError {
      didThrowDecodingError = true
    }

    #expect(didThrowDecodingError)
  }

  @Test
  func decodingIgnoresUnknownFirestoreFields() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("unknown-field-\(UUID().uuidString)")

    try await firestore
      .collection("emulator-users")
      .document(reference.documentID)
      .setData([
        "displayName": "Known",
        "score": 12,
        "active": true,
        "labels": ["known"],
        "unexpected": "ignored"
      ])

    let decoded = try await reference.getDataDocument()

    #expect(decoded.displayName == "Known")
    #expect(decoded.score == 12)
    #expect(decoded.active)
    #expect(decoded.labels == ["known"])
  }

  @Test
  func partialDocumentCanBeInspectedWithoutDecodingAsACompleteModel() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("partial-raw-\(UUID().uuidString)")

    try await firestore
      .collection("emulator-users")
      .document(reference.documentID)
      .setData([
        "displayName": "Partial",
        "score": 7
      ])

    let snapshot = try await reference.getDocument()
    let rawData = snapshot._documentSnapshot.data() ?? [:]

    #expect(rawData["displayName"] as? String == "Partial")
    #expect(rawData["score"] as? Int == 7)
    #expect(rawData["active"] == nil)
    #expect(rawData["labels"] == nil)
  }
}
