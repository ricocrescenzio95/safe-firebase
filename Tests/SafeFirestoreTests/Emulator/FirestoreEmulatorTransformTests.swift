import Foundation
import Testing
import SafeFirestore
import FirebaseFirestore

@FirestoreCollection("emulator-transform-users")
struct TransformUser {
  var score: Int
  var tags: [String]
  var updatedAt: Date
  var nickname: String?
}

extension FirestoreEmulatorTests {
  @Test
  func firestoreTransformsUpdateAndDeleteFields() async throws {
    let reference = firestore
      .collection(TransformUser.self)
      .document("transforms-\(UUID().uuidString)")

    try await reference.setData(from: TransformUser(
      score: 10,
      tags: ["initial"],
      updatedAt: Date(timeIntervalSince1970: 0),
      nickname: "temporary"
    ))

    try await reference.updateData([
      .init(\.score, FirestoreIncrement(5)),
      .init(\.tags, FirestoreArrayUnion(["new"])),
      .init(\.updatedAt, FirestoreServerTimestamp()),
      .init(\.nickname, FirestoreDelete())
    ])

    let snapshot = try await reference.getDocument()
    let rawData = snapshot._documentSnapshot.data() ?? [:]

    #expect(rawData["score"] as? Int == 15)
    #expect(Set(rawData["tags"] as? [String] ?? []) == ["initial", "new"])
    #expect(rawData["updatedAt"] is Timestamp)
    #expect(rawData["nickname"] == nil)
  }

  @Test
  func firestoreArrayRemoveRemovesOnlyTheRequestedValues() async throws {
    let reference = firestore
      .collection(TransformUser.self)
      .document("array-remove-\(UUID().uuidString)")

    try await reference.setData(from: TransformUser(
      score: 0,
      tags: ["keep", "remove", "also-keep"],
      updatedAt: Date(timeIntervalSince1970: 0),
      nickname: nil
    ))

    try await reference.updateData([
      .init(\.tags, FirestoreArrayRemove(["remove"]))
    ])

    let decoded = try await reference.getDataDocument()

    #expect(decoded.tags == ["keep", "also-keep"])
  }
}
