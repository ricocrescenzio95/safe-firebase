import FirebaseFirestore

/// An expression that can be converted into a Firebase Firestore query filter.
public protocol FirestorePredicateExpression {
  /// Builds the Firebase filter represented by the expression.
  func makeFilter() -> Filter
}

// MARK: - FirestorePredicate

/// A typed comparison between a Firestore field and one or more values.
///
/// ```swift
/// let adults = Firestore.firestore()
///     .collection(User.self)
///     .where { $0.age >= 18 }
/// ```
///
/// Schema operators create values of this type.
public struct FirestorePredicate<Value: FirestoreModel> {
  /// The operation applied to the field.
  public enum Operation {
    /// Matches values equal to the supplied value.
    case equal(Value)
    /// Matches values not equal to the supplied value.
    case notEqual(Value)
    /// Matches values less than the supplied value.
    case less(Value)
    /// Matches values less than or equal to the supplied value.
    case lessOrEqual(Value)
    /// Matches values greater than the supplied value.
    case greater(Value)
    /// Matches values greater than or equal to the supplied value.
    case greaterOrEqual(Value)
    /// Matches an array containing the supplied value.
    case arrayContains(Value)
    /// Matches an array equal to the supplied array.
    case arrayEqual([Value])
    /// Matches an array not equal to the supplied array.
    case arrayNotEqual([Value])
    /// Matches an array containing at least one supplied value.
    case arrayContainsAny([Value])
    /// Matches one of the supplied values.
    case `in`([Value])
    /// Excludes the supplied values.
    case notIn([Value])
    /// Matches one of the supplied values.
    case arrayIn([[Value]])
    /// Excludes the supplied values.
    case arrayNotIn([[Value]])
    /// Matches an object equal to the supplied dictionary.
    case mapEqual([String: Value])
    /// Matches an object not equal to the supplied dictionary.
    case mapNotEqual([String: Value])
  }
  /// The path components of the field being compared.
  public let path: [String]
  /// The comparison operation applied to the field.
  public let operation: Operation
  
  init(path: [String], operation: Operation) {
    self.path = path
    self.operation = operation
  }
}

extension FirestorePredicate: Sendable where Value: Sendable {}
extension FirestorePredicate: Equatable where Value: Equatable {}
extension FirestorePredicate: Hashable where Value: Hashable {}
extension FirestorePredicate: Encodable where Value: Encodable {}
extension FirestorePredicate: Decodable where Value: Decodable {}

extension FirestorePredicate.Operation: Sendable where Value: Sendable {}
extension FirestorePredicate.Operation: Equatable where Value: Equatable {}
extension FirestorePredicate.Operation: Hashable where Value: Hashable {}
extension FirestorePredicate.Operation: Encodable where Value: Encodable {}
extension FirestorePredicate.Operation: Decodable where Value: Decodable {}

extension FirestorePredicate: FirestorePredicateExpression {
  /// Converts the predicate into the corresponding Firebase query filter.
  public func makeFilter() -> Filter {
    switch operation {
    case .equal(let value):
        .whereField(
          FieldPath(path), isEqualTo: value.firestoreValue
        )
    case .notEqual(let value):
        .whereField(
          FieldPath(path), isNotEqualTo: value.firestoreValue
        )
    case .less(let value):
        .whereField(
          FieldPath(path), isLessThan: value.firestoreValue
        )
    case .lessOrEqual(let value):
        .whereField(
          FieldPath(path), isLessThanOrEqualTo: value.firestoreValue
        )
    case .greater(let value):
        .whereField(
          FieldPath(path), isGreaterThan: value.firestoreValue
        )
    case .greaterOrEqual(let value):
        .whereField(
          FieldPath(path), isGreaterOrEqualTo: value.firestoreValue
        )
    case .arrayContains(let value):
        .whereField(
          FieldPath(path), arrayContains: value.firestoreValue
        )
    case .arrayEqual(let values):
        .whereField(
          FieldPath(path), isEqualTo: values.map(\.firestoreValue)
        )
    case .arrayNotEqual(let values):
        .whereField(
          FieldPath(path), isNotEqualTo: values.map(\.firestoreValue)
        )
    case .arrayContainsAny(let values):
        .whereField(
          FieldPath(path), arrayContainsAny: values.map(\.firestoreValue)
        )
    case .in(let values):
        .whereField(
          FieldPath(path), in: values.map(\.firestoreValue)
        )
    case .notIn(let values):
        .whereField(
          FieldPath(path), notIn: values.map(\.firestoreValue)
        )
    case.arrayIn(let values):
        .whereField(
          FieldPath(path), in: values.map(\.firestoreValue)
        )
    case .arrayNotIn(let values):
        .whereField(
          FieldPath(path), notIn: values.map(\.firestoreValue)
        )
    case .mapEqual(let map):
        .whereField(
          FieldPath(path), isEqualTo: map.firestoreValue
        )
    case .mapNotEqual(let map):
        .whereField(
          FieldPath(path), isNotEqualTo: map.firestoreValue
        )
    }
  }
}

// MARK: - And

/// A logical AND of two ``FirestorePredicateExpression`` values.
public struct FirestoreAndExpression<L: FirestorePredicateExpression, R: FirestorePredicateExpression>: FirestorePredicateExpression {
  public let lhs: L
  public let rhs: R
  
  /// Converts both expressions into a single AND filter.
  public func makeFilter() -> Filter {
    .andFilter([
      lhs.makeFilter(),
      rhs.makeFilter()
    ])
  }
}

extension FirestoreAndExpression: Sendable where L: Sendable, R: Sendable {}
extension FirestoreAndExpression: Equatable where L: Equatable, R: Equatable {}
extension FirestoreAndExpression: Hashable where L: Hashable, R: Hashable {}
extension FirestoreAndExpression: Decodable where L: Decodable, R: Decodable {}
extension FirestoreAndExpression: Encodable where L: Encodable, R: Encodable {}

/// Combines two ``FirestorePredicateExpression`` values with a logical AND.
public func && <L: FirestorePredicateExpression, R: FirestorePredicateExpression>(
  lhs: L,
  rhs: R
) -> FirestoreAndExpression<L, R> {
  FirestoreAndExpression(lhs: lhs, rhs: rhs)
}

// MARK: - Or

/// A logical OR of two ``FirestorePredicateExpression`` values.
public struct FirestoreOrExpression<L: FirestorePredicateExpression, R: FirestorePredicateExpression>: FirestorePredicateExpression {
  public let lhs: L
  public let rhs: R
  
  /// Converts both expressions into a single OR filter.
  public func makeFilter() -> Filter {
    .orFilter([
      lhs.makeFilter(),
      rhs.makeFilter()
    ])
  }
}

extension FirestoreOrExpression: Sendable where L: Sendable, R: Sendable {}
extension FirestoreOrExpression: Equatable where L: Equatable, R: Equatable {}
extension FirestoreOrExpression: Hashable where L: Hashable, R: Hashable {}
extension FirestoreOrExpression: Decodable where L: Decodable, R: Decodable {}
extension FirestoreOrExpression: Encodable where L: Encodable, R: Encodable {}

/// Combines two ``FirestorePredicateExpression`` values with a logical OR.
public func || <L: FirestorePredicateExpression, R: FirestorePredicateExpression>(
  lhs: L,
  rhs: R
) -> FirestoreOrExpression<L, R> {
  FirestoreOrExpression(lhs: lhs, rhs: rhs)
}

// MARK: - Bool special cases

extension FirestoreSchema<Bool>: FirestorePredicateExpression {
  public func makeFilter() -> Filter {
    .whereField(FieldPath(_firestorePath), isEqualTo: true)
  }
}

/// A predicate expression that matches a Boolean field whose value is false.
public struct NegatedFieldFirestoreExpression: FirestorePredicateExpression {
  /// The path of the Boolean field being negated.
  public let path: [String]

  /// Builds a filter that matches the field when its value is false.
  public func makeFilter() -> Filter {
    .whereField(FieldPath(path), isEqualTo: false)
  }
}

/// Negates a Boolean schema field.
///
/// - Parameter field: The Boolean schema field to match when false.
/// - Returns: A predicate expression equivalent to comparing the field with false.
///
/// ```swift
/// let inactive = Firestore.firestore()
///     .collection(User.self)
///     .where { !$0.isActive }
/// ```
public prefix func !(
  field: FirestoreSchema<Bool>,
) -> NegatedFieldFirestoreExpression {
  NegatedFieldFirestoreExpression(path: field._firestorePath)
}

// MARK: - Optional special cases

public protocol FirestoreOptional {
  associatedtype Wrapped
}
extension Optional: FirestoreOptional {}

/// A predicate expression that checks whether an optional field is null or non-null.
public struct NullCheckFirestoreExpression: FirestorePredicateExpression {
  /// The path of the optional field being checked.
  public let path: [String]

  /// Whether this expression matches a null value.
  ///
  /// When true, the expression matches fields whose value is null. When
  /// false, it matches fields whose value is not null.
  public let isNull: Bool

  /// Builds a Firestore null-check filter.
  public func makeFilter() -> Filter {
    isNull
      ? .whereField(FieldPath(path), isEqualTo: NSNull())
      : .whereField(FieldPath(path), isNotEqualTo: NSNull())
  }
}

extension FirestoreSchemaProtocol where Value: FirestoreOptional {
  /// Creates a predicate that matches documents where the optional field is null.
  ///
  /// This is useful for fields that are absent or explicitly stored as null.
  ///
  /// ```swift
  /// let missingNickname = Firestore.firestore()
  ///     .collection(User.self)
  ///     .where { $0.nickname.isNull }
  /// ```
  public var isNull: NullCheckFirestoreExpression {
    NullCheckFirestoreExpression(
      path: _firestorePath,
      isNull: true
    )
  }
  
  /// Creates a predicate that matches documents where the optional field is not null.
  ///
  /// ```swift
  /// let usersWithNickname = Firestore.firestore()
  ///     .collection(User.self)
  ///     .where { $0.nickname.isNotNull }
  /// ```
  public var isNotNull: NullCheckFirestoreExpression {
    NullCheckFirestoreExpression(
      path: _firestorePath,
      isNull: false
    )
  }
}
