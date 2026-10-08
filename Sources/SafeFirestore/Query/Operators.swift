import Foundation
import FirebaseFirestore

/// A schema whose value supports scalar equality predicates.
public protocol FirestoreModelPredicateSchema<PredicateValue>: FirestoreSchemaProtocol {
  associatedtype PredicateValue: FirestoreModel
}

/// A scalar predicate schema whose value supports range comparisons.
public protocol FirestoreComparablePredicateSchema: FirestoreModelPredicateSchema
where PredicateValue: FirestoreComparable {}

/// A schema for set-like array predicates such as arrayContains.
public protocol FirestoreArrayPredicateSchema<Element>: FirestoreSchemaProtocol {
  associatedtype Element: FirestoreModel
}

/// A schema for array membership operators.
public protocol FirestoreArrayMembershipPredicateSchema<Element>: FirestoreSchemaProtocol {
  associatedtype Element: FirestoreModel
}

/// A schema for array equality and array membership predicates.
public protocol FirestoreArrayEqualityPredicateSchema: FirestoreSchemaProtocol {
  associatedtype Element: FirestoreModel
}

/// A schema for dictionary equality predicates.
public protocol FirestoreMapPredicateSchema<Element>: FirestoreSchemaProtocol {
  associatedtype Element: FirestoreModel
}

extension FirestoreSchema: FirestoreModelPredicateSchema where Value: FirestoreModel {
  public typealias PredicateValue = Value
}

extension FirestoreSchema: FirestoreComparablePredicateSchema where Value: FirestoreComparable {}

extension FirestoreSchema: FirestoreArrayEqualityPredicateSchema
where Value: FirestoreArraySchemaValue {
  public typealias Element = Value.Element
}

extension FirestoreSchema: FirestoreArrayPredicateSchema
where Value: FirestoreSetSchemaValue {
  public typealias Element = Value.Element
}

extension FirestoreSchema: FirestoreArrayMembershipPredicateSchema
where Value: FirestoreArrayMembershipSchemaValue {
  public typealias Element = Value.Element
}

extension FirestoreSchema: FirestoreMapPredicateSchema
where Value: FirestoreMapSchemaValue {
  public typealias Element = Value.Element
}

extension FirestoreOptionalSchema: FirestoreModelPredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreModelPredicateSchema {
  public typealias PredicateValue = Wrapped.Schema.PredicateValue
}

extension FirestoreOptionalSchema: FirestoreComparablePredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreComparablePredicateSchema {}

extension FirestoreOptionalSchema: FirestoreArrayPredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreArrayPredicateSchema {
  public typealias Element = Wrapped.Schema.Element
}

extension FirestoreOptionalSchema: FirestoreArrayMembershipPredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreArrayMembershipPredicateSchema {
  public typealias Element = Wrapped.Schema.Element
}

extension FirestoreOptionalSchema: FirestoreArrayEqualityPredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreArrayEqualityPredicateSchema {
  public typealias Element = Wrapped.Schema.Element
}

extension FirestoreOptionalSchema: FirestoreMapPredicateSchema
where Wrapped: FirestoreModel, Wrapped.Schema: FirestoreMapPredicateSchema {
  public typealias Element = Wrapped.Schema.Element
}

extension FirestoreSchema where Value: FirestoreMapSchemaValue {
  @_disfavoredOverload
  /// Returns the schema for a dictionary value at the specified key.
  public subscript(key: String) -> FirestoreSchema<Value.Element> {
    FirestoreSchema<Value.Element>(path: _firestorePath + [key])
  }
}

extension FirestoreModelPredicateSchema {
  @_disfavoredOverload
  /// Creates an equality predicate for the schema path.
  public static func == (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .equal(rhs))
  }

  @_disfavoredOverload
  /// Creates an inequality predicate for the schema path.
  public static func != (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .notEqual(rhs))
  }
}

extension FirestoreArrayEqualityPredicateSchema {
  /// Creates an equality predicate for an array value.
  public static func == (lhs: Self, rhs: [Element]) -> FirestorePredicate<Element> {
    .init(path: lhs._firestorePath, operation: .arrayEqual(rhs))
  }

  /// Creates an inequality predicate for an array value.
  public static func != (lhs: Self, rhs: [Element]) -> FirestorePredicate<Element> {
    .init(path: lhs._firestorePath, operation: .arrayNotEqual(rhs))
  }

  /// Creates an array-in predicate.
  public func isIn(_ values: [[Element]]) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayIn(values))
  }

  /// Creates an array-not-in predicate.
  public func isNotIn(_ values: [[Element]]) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayNotIn(values))
  }
}

extension FirestoreMapPredicateSchema {
  /// Creates an equality predicate for a dictionary value.
  public static func == (lhs: Self, rhs: [String: Element]) -> FirestorePredicate<Element> {
    .init(path: lhs._firestorePath, operation: .mapEqual(rhs))
  }

  /// Creates an inequality predicate for a dictionary value.
  public static func != (lhs: Self, rhs: [String: Element]) -> FirestorePredicate<Element> {
    .init(path: lhs._firestorePath, operation: .mapNotEqual(rhs))
  }
}

extension FirestoreComparablePredicateSchema {
  /// Creates a less-than predicate.
  public static func < (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .less(rhs))
  }

  /// Creates a greater-than predicate.
  public static func > (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .greater(rhs))
  }

  /// Creates a greater-than-or-equal predicate.
  public static func >= (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .greaterOrEqual(rhs))
  }

  /// Creates a less-than-or-equal predicate.
  public static func <= (lhs: Self, rhs: PredicateValue) -> FirestorePredicate<PredicateValue> {
    .init(path: lhs._firestorePath, operation: .lessOrEqual(rhs))
  }
}

extension FirestoreModelPredicateSchema {
  @_disfavoredOverload
  /// Creates an in predicate.
  public func isIn(_ values: [PredicateValue]) -> FirestorePredicate<PredicateValue> {
    .init(path: _firestorePath, operation: .in(values))
  }

  @_disfavoredOverload
  /// Creates a not-in predicate.
  public func isNotIn(_ values: [PredicateValue]) -> FirestorePredicate<PredicateValue> {
    .init(path: _firestorePath, operation: .notIn(values))
  }
}

extension FirestoreArrayMembershipPredicateSchema {
  /// Creates an `array-contains` predicate.
  public func arrayContains(_ value: Element) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayContains(value))
  }

  /// Creates an `array-contains-any` predicate.
  public func arrayContainsAny(_ values: [Element]) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayContainsAny(values))
  }
}

extension FirestoreArrayPredicateSchema {
  /// Creates an array-in predicate.
  public func isIn(_ values: [[Element]]) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayIn(values))
  }

  /// Creates an array-not-in predicate.
  public func isNotIn(_ values: [[Element]]) -> FirestorePredicate<Element> {
    .init(path: _firestorePath, operation: .arrayNotIn(values))
  }
}
