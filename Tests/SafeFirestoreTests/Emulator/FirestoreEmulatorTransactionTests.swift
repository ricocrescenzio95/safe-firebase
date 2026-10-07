import Foundation
import Testing
import SafeFirestore

private enum TransactionTestError: Error {
  case expected
}

extension FirestoreEmulatorTests {
  @Test
  func typedTransactionReadsAndReturnsAValueAfterUpdating() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("transaction-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "Transaction",
      score: 10,
      active: false,
      labels: ["initial"],
      profile: nil
    ))

    let nextScore: Int = try await firestore.runTypedTransaction { transaction in
      let snapshot = try transaction.getDocument(reference)
      let current = try snapshot.data()
      let next = current.score + 5
      transaction.updateData([
        .init(\.score, next),
        .init(\.active, true)
      ], forDocument: reference)
      return next
    }

    let updated = try await reference.getDataDocument()
    #expect(nextScore == 15)
    #expect(updated.score == 15)
    #expect(updated.active)
  }

  @Test
  func transactionPropagatesErrorsAndDoesNotCommitWrites() async throws {
    let reference = firestore
      .collection(EmulatorUser.self)
      .document("transaction-error-\(UUID().uuidString)")

    try await reference.setData(from: EmulatorUser(
      displayName: "Before",
      score: 10,
      active: false,
      labels: [],
      profile: nil
    ))

    var didThrow = false

    do {
      _ = try await firestore.runTypedTransaction { transaction in
        let snapshot = try transaction.getDocument(reference)
        let current = try snapshot.data()

        transaction.updateData(
          [.init(\.score, current.score + 1)],
          forDocument: reference
        )

        throw TransactionTestError.expected
      } as Int
    } catch {
      didThrow = true
    }

    #expect(didThrow)
    #expect((try await reference.getDataDocument()).score == 10)
  }
}
