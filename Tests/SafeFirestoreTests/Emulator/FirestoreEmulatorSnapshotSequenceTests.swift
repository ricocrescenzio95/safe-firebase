import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  @available(macOS 15.0, *)
  func documentSnapshotsEmitInitialAndUpdatedValues() async throws {
    let reference = firestore.collection(EmulatorUser.self)
      .document("document-stream-\(UUID().uuidString)")
    var iterator = reference.snapshots.makeAsyncIterator()

    try await reference.setData(from: EmulatorUser(
      displayName: "Initial", score: 1, active: true, labels: [], profile: nil
    ))
    let initial = try await iterator.next()

    try await reference.updateData([.init(\.score, 2)])
    let updated = try await iterator.next()

    #expect(try initial?.data().score == 1)
    #expect(try updated?.data().score == 2)
  }

  @Test
  @available(macOS 15.0, *)
  func querySnapshotsEmitDocumentsMatchingTheQuery() async throws {
    let reference = firestore.collection(EmulatorUser.self)
    let displayName = "Matching-\(UUID().uuidString)"
    let query = reference.where { $0.active == true && $0.displayName == displayName }
    var iterator = query.snapshots.makeAsyncIterator()

    try await reference.document("query-stream-\(UUID().uuidString)")
      .setData(from: EmulatorUser(
        displayName: displayName, score: 1, active: true, labels: [], profile: nil
      ))
    let snapshot = try await iterator.next()

    #expect(snapshot?.count == 1)
    #expect(try snapshot?.documents.first?.data().active == true)
  }

  @Test
  @available(macOS 15.0, *)
  func snapshotSequenceCanBeCancelledWithoutLeavingAListener() async throws {
    let reference = firestore.collection(EmulatorUser.self)
      .document("cancel-stream-\(UUID().uuidString)")
    var iterator = reference.snapshots.makeAsyncIterator()
    let task = Task {
      try await iterator.next()
    }

    task.cancel()
    _ = try? await task.value

    try await reference.setData(from: EmulatorUser(
      displayName: "After cancellation", score: 1, active: true, labels: [], profile: nil
    ))
    #expect(task.isCancelled)
  }
}
