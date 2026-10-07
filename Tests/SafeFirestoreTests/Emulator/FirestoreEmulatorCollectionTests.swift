import Foundation
import Testing
import SafeFirestore

@FirestoreCollection("emulator-children")
struct EmulatorChild {
  var name: String
  var score: Int
}

extension FirestoreEmulatorTests {
  @Test
  func typedCollectionExposesItsIdentityAndPath() {
    let collection = firestore.collection(EmulatorUser.self)

    #expect(collection.collectionID == "emulator-users")
    #expect(collection.path == "emulator-users")
    #expect(collection.firestore === firestore)
    #expect(collection.parent(EmulatorUser.self) == nil)
  }

  @Test
  func addDocumentCreatesAndReturnsAStoredDocumentSynchronously() throws {
    let collection = firestore.collection(EmulatorUser.self)
    let reference = try collection.addDocument(from: EmulatorUser(
      displayName: "Sync add",
      score: 1,
      active: true,
      labels: [],
      profile: nil
    ))

    #expect(!reference.documentID.isEmpty)
    #expect(reference.path.hasPrefix("emulator-users/"))
  }

  @Test
  func addDocumentCreatesAndReturnsAStoredDocumentAsynchronously() async throws {
    let collection = firestore.collection(EmulatorUser.self)
    let reference = try await collection.addDocument(from: EmulatorUser(
      displayName: "Async add",
      score: 2,
      active: false,
      labels: [],
      profile: nil
    ))

    let decoded = try await reference.getDataDocument()
    #expect(!reference.documentID.isEmpty)
    #expect(decoded.displayName == "Async add")
  }

  @Test
  func documentWithoutAnIDGeneratesAUniqueReference() {
    let collection = firestore.collection(EmulatorUser.self)
    let first = collection.document()
    let second = collection.document()

    #expect(!first.documentID.isEmpty)
    #expect(first.documentID != second.documentID)
    #expect(first.path.hasPrefix("emulator-users/"))
  }

  @Test
  func nestedCollectionReturnsItsTypedParent() async throws {
    let parent = firestore.collection(EmulatorUser.self)
      .document("parent-\(UUID().uuidString)")
    let children = parent.collection(EmulatorChild.self)
    let child = children.document("child")

    try await child.setData(from: EmulatorChild(name: "Nested", score: 3))

    #expect(children.path == "emulator-users/\(parent.documentID)/emulator-children")
    #expect(children.parent(EmulatorUser.self)?.documentID == parent.documentID)
    #expect(try await child.getDataDocument().name == "Nested")
  }

  @Test
  func collectionGroupReadsNestedCollections() async throws {
    let firstParent = firestore.collection(EmulatorUser.self)
      .document("group-parent-1-\(UUID().uuidString)")
    let secondParent = firestore.collection(EmulatorUser.self)
      .document("group-parent-2-\(UUID().uuidString)")

    try await firstParent.collection(EmulatorChild.self)
      .document("first")
      .setData(from: EmulatorChild(name: "First", score: 1))
    try await secondParent.collection(EmulatorChild.self)
      .document("second")
      .setData(from: EmulatorChild(name: "Second", score: 2))

    let snapshot = try await firestore.collectionGroup(EmulatorChild.self)
      .getDocuments()
    let names = Set(try snapshot.documents.map { try $0.data().name })

    #expect(names == ["First", "Second"])
  }
}
