import Foundation
import FirebaseFirestore

/// A ``FirestoreModel`` that can be used with range comparison predicates.
public protocol FirestoreComparable: FirestoreModel {}

/// A ``FirestoreModel`` that can be used with equality predicates.
public protocol FirestoreEquatable: FirestoreModel {}

extension String: FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Bool: FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension GeoPoint: FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<GeoPoint> { .init(_firestorePath: path) }
}
extension DocumentReference: FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<DocumentReference> { .init(_firestorePath: path) }
}
extension Data: FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}

extension Int: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Int64: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Int32: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Int16: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Int8: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}

extension Double: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Float: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Float16: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}

extension Date: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Self> { .init(_firestorePath: path) }
}
extension Timestamp: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public var firestoreValue: Any { self }
  public static func schema(path: [String]) -> FirestoreSchema<Timestamp> { .init(_firestorePath: path) }
}

extension Optional: FirestoreModel where Wrapped: FirestoreModel {
  /// The wrapped Firestore value, or NSNull when the optional is nil.
  public var firestoreValue: Any { self?.firestoreValue ?? NSNull() }
    
  public static func schema(path: [String]) -> FirestoreOptionalSchema<Wrapped> {
    FirestoreOptionalSchema(_firestorePath: path)
  }
}
extension Optional: FirestoreEquatable where Wrapped: FirestoreEquatable {}

extension FirestoreModel where Self: RawRepresentable, RawValue: FirestoreModel {
  /// The Firestore representation of the raw value.
  public var firestoreValue: Any { rawValue.firestoreValue }
}

public protocol FirestoreArraySchemaValue {
  associatedtype Element: FirestoreModel
}

public protocol FirestoreSetSchemaValue {
  associatedtype Element: FirestoreModel
}

/// A collection value that supports array membership operators.
public protocol FirestoreArrayMembershipSchemaValue {
  associatedtype Element: FirestoreModel
}

public protocol FirestoreMapSchemaValue {
  associatedtype Element: FirestoreModel
}

extension Array: FirestoreArraySchemaValue, FirestoreArrayMembershipSchemaValue
where Element: FirestoreModel {}
extension Set: FirestoreSetSchemaValue, FirestoreArrayMembershipSchemaValue
where Element: FirestoreModel {}
extension Dictionary: FirestoreMapSchemaValue where Key == String, Value: FirestoreModel {
  public typealias Element = Value
}

extension Array: FirestoreModel where Element: FirestoreModel {
  public var firestoreValue: Any { map(\.firestoreValue) }
  
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}
extension Array: FirestoreEquatable where Element: FirestoreEquatable {}

extension Set: FirestoreModel where Element: FirestoreModel {
  public var firestoreValue: Any { map(\.firestoreValue) }
  
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}

extension Dictionary: FirestoreModel where Key == String, Value: FirestoreModel {
  public var firestoreValue: Any { mapValues(\.firestoreValue) }
  
  public static func schema(path: [String]) -> FirestoreSchema<Self> {
    Schema(_firestorePath: path)
  }
}
extension Dictionary: FirestoreEquatable where Key == String, Value: FirestoreEquatable {}
