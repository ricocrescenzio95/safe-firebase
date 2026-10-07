import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func typedSnapshotsReadFieldsAndDocumentsFromServer() async throws {
    let reference = firestore.collection(EmulatorUser.self)
      .document("read-source-\(UUID().uuidString)")
    let model = EmulatorUser(
      displayName: "Server", score: 42, active: true, labels: ["source"], profile: nil
    )

    try await reference.setData(from: model)

    let documentSnapshot = try await reference.getDocument(source: .server)
    let querySnapshot = try await firestore.collection(EmulatorUser.self)
      .where { $0.displayName == "Server" }
      .getDocuments(source: .server)

    let score: Int? = documentSnapshot.get(.init(\.score))

    #expect(documentSnapshot.exists)
    #expect(score == 42)
    #expect(try documentSnapshot.data().displayName == "Server")
    #expect(querySnapshot.documents.count == 1)
  }

  @Test
  @available(macOS 15.0, *)
  func snapshotSequencesAcceptMetadataChangesOption() async throws {
    let reference = firestore.collection(EmulatorUser.self)
      .document("metadata-stream-\(UUID().uuidString)")
    let displayName = "Metadata-\(UUID().uuidString)"
    var documentIterator = reference.snapshots(includeMetadataChanges: true).makeAsyncIterator()
    var queryIterator = firestore.collection(EmulatorUser.self)
      .where { $0.displayName == displayName }
      .snapshots(includeMetadataChanges: true)
      .makeAsyncIterator()

    try await reference.setData(from: EmulatorUser(
      displayName: displayName, score: 1, active: true, labels: [], profile: nil
    ))

    #expect(try await documentIterator.next() != nil)
    #expect(try await queryIterator.next() != nil)
  }
}
