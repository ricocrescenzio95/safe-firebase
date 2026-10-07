import Foundation
import Testing
@testable import SafeFirestore
import FirebaseFirestore

struct AggregateTests {
  @Test
  func aggregateFieldsPreserveTheSourceFieldType() {
    let integerSum: TypedAggregateField<TestUser, Int> = .sum(\.age)
    let optionalIntegerSum: TypedAggregateField<TestUser, Int> = .sum(\.optionalAge)
    let doubleSum: TypedAggregateField<TestUser, Double> = .sum(\.profile.settings.precision)
    let average: TypedAggregateField<TestUser, Double> = .average(\.age)
    let count: TypedAggregateField<TestUser, Int> = .count()

    _ = integerSum
    _ = optionalIntegerSum
    _ = doubleSum
    _ = average
    _ = count
  }
}
