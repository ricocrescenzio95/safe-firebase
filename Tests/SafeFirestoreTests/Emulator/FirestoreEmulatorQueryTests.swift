import Foundation
import Testing
import SafeFirestore

extension FirestoreEmulatorTests {
  @Test
  func queriesTypedDocumentsWithNestedPredicates() async throws {
    let collection = firestore.collection(EmulatorUser.self)
    let prefix = "query-\(UUID().uuidString)"
    let matching = collection.document("\(prefix)-matching")
    let nonMatching = collection.document("\(prefix)-nonmatching")

    try await matching.setData(from: EmulatorUser(
      displayName: "Matching", score: 80, active: true,
      labels: ["swift"], profile: EmulatorProfile(city: "Milan", visits: 10)
    ))
    try await nonMatching.setData(from: EmulatorUser(
      displayName: "Non matching", score: 20, active: false,
      labels: ["other"], profile: EmulatorProfile(city: "Rome", visits: 1)
    ))

    let snapshot = try await collection
      .where { $0.score >= 50 && $0.active }
      .getDocuments()
    let users = try snapshot.documents.map { try $0.data() }
    let ids = Set(snapshot.documents.map(\.documentID))

    #expect(snapshot.count == 1)
    #expect(ids == [matching.documentID])
    #expect(users.first?.displayName == "Matching")
    #expect(users.first?.profile?.city == "Milan")
  }

  @Test
  func typedAggregateQueryReturnsTheDocumentCount() async throws {
    let collection = firestore.collection(EmulatorUser.self)
    let first = collection.document("aggregate-first-\(UUID().uuidString)")
    let second = collection.document("aggregate-second-\(UUID().uuidString)")
    let model = EmulatorUser(
      displayName: "Aggregate", score: 1, active: true,
      labels: [], profile: nil
    )

    try await first.setData(from: model)
    try await second.setData(from: model)

    let aggregate = try await collection
      .where { $0.active == true }
      .count
      .getAggregation()

    #expect(aggregate.count == 2)
  }

  @Test
  func typedAggregateQueryDecodesTypedSumAndAverage() async throws {
    let collection = firestore.collection(EmulatorUser.self)
    let first = collection.document("aggregate-sum-first-\(UUID().uuidString)")
    let second = collection.document("aggregate-sum-second-\(UUID().uuidString)")

    try await first.setData(from: EmulatorUser(
      displayName: "First", score: 2, active: true, labels: [], profile: nil
    ))
    try await second.setData(from: EmulatorUser(
      displayName: "Second", score: 4, active: true, labels: [], profile: nil
    ))

    let result = try await collection
      .aggregate([.sum(\.score), .average(\.score)])
      .getAggregation()
    let total: Int? = result.get(.sum(\.score))
    let average: Double? = result.get(.average(\.score))

    #expect(total == 6)
    #expect(average == 3)
  }
}
