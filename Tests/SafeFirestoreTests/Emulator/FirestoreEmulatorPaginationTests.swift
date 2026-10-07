import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  private func seedOrderedUsers() async throws -> TypedCollectionReference<EmulatorUser> {
    let collection = firestore.collection(EmulatorUser.self)
    for score in [10, 20, 30] {
      try await collection.document("ordered-\(score)-\(UUID().uuidString)")
        .setData(from: EmulatorUser(
          displayName: "User \(score)",
          score: score,
          active: true,
          labels: [],
          profile: nil
        ))
    }
    return collection
  }

  @Test
  func queryOrdersAscendingAndDescending() async throws {
    let collection = try await seedOrderedUsers()

    let ascending = try await collection
      .order(by: { $0.score })
      .getDocuments()
    let descending = try await collection
      .order(by: { $0.score }, descending: true)
      .getDocuments()

    #expect(try ascending.documents.map { try $0.data().score } == [10, 20, 30])
    #expect(try descending.documents.map { try $0.data().score } == [30, 20, 10])
  }

  @Test
  func querySupportsLimitsAndValueCursors() async throws {
    let collection = try await seedOrderedUsers()
    let ordered = collection.order(by: { $0.score })

    let first = try await ordered.limit(to: 2).getDocuments()
    let last = try await ordered.limit(toLast: 2).getDocuments()
    let afterTwenty = try await ordered.start(after: [20]).getDocuments()
    let throughTwenty = try await ordered.end(at: [20]).getDocuments()
    let beforeTwenty = try await ordered.end(before: [20]).getDocuments()

    #expect(try first.documents.map { try $0.data().score } == [10, 20])
    #expect(try last.documents.map { try $0.data().score } == [20, 30])
    #expect(try afterTwenty.documents.map { try $0.data().score } == [30])
    #expect(try throughTwenty.documents.map { try $0.data().score } == [10, 20])
    #expect(try beforeTwenty.documents.map { try $0.data().score } == [10])
  }

  @Test
  func querySupportsDocumentSnapshotCursors() async throws {
    let collection = try await seedOrderedUsers()
    let ordered = collection.order(by: { $0.score })
    let pivotDocument = try await ordered.limit(to: 1).getDocuments().documents[0]
    let pivot = try await collection.document(pivotDocument.documentID).getDocument()

    let atPivot = try await ordered.start(atDocument: pivot).getDocuments()
    let afterPivot = try await ordered.start(afterDocument: pivot).getDocuments()
    let throughPivot = try await ordered.end(atDocument: pivot).getDocuments()
    let beforePivot = try await ordered.end(beforeDocument: pivot).getDocuments()

    #expect(atPivot.count == 3)
    #expect(afterPivot.count == 2)
    #expect(throughPivot.count == 1)
    #expect(beforePivot.count == 0)
  }
}
