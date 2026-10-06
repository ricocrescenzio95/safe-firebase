import Foundation
import FirebaseFirestore

/// A value that can be represented in a Firestore document.
///
/// Raw-representable values use their raw value by default, and nil optionals are represented by `NSNull`.
///
/// ```swift
/// enum Status: String, Codable, FirestoreValue, FirestoreModel {
///     case active
///     case archived
/// }
///
/// let value = Status.active.firestoreValue as? String
/// // value == "active"
/// ```
public protocol FirestoreValue: FirestoreModel {
  /// The value passed to the Firebase Firestore SDK.
  var firestoreValue: Any { get }
}

/// A ``FirestoreValue`` that can be used with range comparison predicates.
/// A Firestore value that supports range comparisons in queries.
public protocol FirestoreComparable: FirestoreValue {}

/// A ``FirestoreValue`` that can be used with equality predicates.
/// A Firestore value that supports equality predicates in queries.
public protocol FirestoreEquatable: FirestoreValue {}

extension FirestoreValue {
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}

extension String: FirestoreValue, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Bool: FirestoreValue, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension GeoPoint: FirestoreValue, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension DocumentReference: FirestoreValue, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Data: FirestoreValue, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}

extension Int: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Int64: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Double: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Date: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}
extension Timestamp: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
}

extension Optional: FirestoreValue where Wrapped: FirestoreValue {
  /// The wrapped Firestore value, or NSNull when the optional is nil.
  public var firestoreValue: Any { self?.firestoreValue ?? NSNull() }
}

extension Optional: FirestoreModel where Wrapped: FirestoreModel {
  public typealias Schema = FirestoreOptionalSchema<Wrapped>
  
  public static func schema(path: [String]) -> Schema {
    FirestoreOptionalSchema(_firestorePath: path)
  }
}
extension Optional: FirestoreEquatable where Wrapped: FirestoreEquatable {}

extension FirestoreValue where Self: RawRepresentable, RawValue: FirestoreValue {
  /// The Firestore representation of the raw value.
  public var firestoreValue: Any { rawValue.firestoreValue }
}

public protocol FirestoreArraySchemaValue {
  associatedtype Element: FirestoreValue
}

public protocol FirestoreSetSchemaValue {
  associatedtype Element: FirestoreValue
}

/// A collection value that supports array membership operators.
public protocol FirestoreArrayMembershipSchemaValue {
  associatedtype Element: FirestoreValue
}

public protocol FirestoreMapSchemaValue {
  associatedtype Element: FirestoreValue
}

extension Array: FirestoreArraySchemaValue, FirestoreArrayMembershipSchemaValue
where Element: FirestoreValue {}
extension Set: FirestoreSetSchemaValue, FirestoreArrayMembershipSchemaValue
where Element: FirestoreValue {}
extension Dictionary: FirestoreMapSchemaValue where Key == String, Value: FirestoreValue {
  public typealias Element = Value
}

extension Array: FirestoreValue where Element: FirestoreValue {
  public var firestoreValue: Any { self }
}
extension Array: FirestoreModel where Element: FirestoreModel {
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}
extension Array: FirestoreEquatable where Element: FirestoreEquatable {}

extension Set: FirestoreValue where Element: FirestoreValue {
  public var firestoreValue: Any { map(\.firestoreValue) }
}
extension Set: FirestoreModel where Element: FirestoreModel {
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}

extension Dictionary: FirestoreValue where Key == String, Value: FirestoreValue {
  public var firestoreValue: Any { mapValues(\.firestoreValue) }
}
extension Dictionary: FirestoreModel where Key == String, Value: FirestoreModel {
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}
extension Dictionary: FirestoreEquatable where Key == String, Value: FirestoreEquatable {}
