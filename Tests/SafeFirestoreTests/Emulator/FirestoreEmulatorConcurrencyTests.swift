import Testing
import SafeFirestore
import Foundation

extension FirestoreEmulatorTests {
  @Test
  func independentConcurrentWritesRemainIsolated() async throws {
    let documents = (0..<8).map { index in
      firestore
        .collection(EmulatorUser.self)
        .document("concurrent-\(index)-\(UUID().uuidString)")
    }

    try await withThrowingTaskGroup(of: Void.self) { group in
      for (index, reference) in documents.enumerated() {
        group.addTask {
          try await reference.setData(from: EmulatorUser(
            displayName: "User \(index)",
            score: index,
            active: index.isMultiple(of: 2),
            labels: ["\(index)"],
            profile: nil
          ))
        }
      }

      try await group.waitForAll()
    }

    try await withThrowingTaskGroup(of: EmulatorUser.self) { group in
      for reference in documents {
        group.addTask {
          try await reference.getDataDocument()
        }
      }

      var decoded = [EmulatorUser]()
      for try await user in group {
        decoded.append(user)
      }

      #expect(decoded.count == documents.count)
      #expect(Set(decoded.map(\.displayName)).count == documents.count)
    }
  }

  @Test
  func concurrentTransactionsDoNotLoseUpdates() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("concurrent-transaction-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "Counter",
      score: 0,
      active: false,
      labels: [],
      profile: nil
    ))

    let numberOfUpdates = 5

    try await withThrowingTaskGroup(of: Int.self) { group in
      for _ in 0..<numberOfUpdates {
        group.addTask {
          try await firestore.runTypedTransaction { transaction in
            let snapshot = try transaction.getDocument(reference)
            let current = try snapshot.data()
            let nextScore = current.score + 1

            transaction.updateData(
              [.init(\.score, nextScore)],
              forDocument: reference
            )

            return nextScore
          }
        }
      }

      try await group.waitForAll()
    }

    #expect((try await reference.getDataDocument()).score == numberOfUpdates)
  }
}
