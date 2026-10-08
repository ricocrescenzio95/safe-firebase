import Foundation
import FirebaseFirestore

/// A ``FirestoreModel`` that can be used with range comparison predicates.
public protocol FirestoreComparable: FirestoreModel {}

/// A ``FirestoreModel`` that can be used with equality predicates.
public protocol FirestoreEquatable: FirestoreModel {}

extension String: FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Bool: FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension GeoPoint: FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<GeoPoint>
  public var firestoreValue: Any { self }
}
extension DocumentReference: FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<DocumentReference>
  public var firestoreValue: Any { self }
}
extension Data: FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}

extension Int: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Int64: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Int32: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Int16: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Int8: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}

extension Double: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Float: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Float16: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}

extension Date: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { self }
}
extension Timestamp: FirestoreComparable, FirestoreModel, FirestoreEquatable {
  public typealias Schema = FirestoreSchema<Timestamp>
  public var firestoreValue: Any { self }
}

extension Optional: FirestoreModel where Wrapped: FirestoreModel {
  public typealias Schema = FirestoreOptionalSchema<Wrapped>
  /// The wrapped Firestore value, or NSNull when the optional is nil.
  public var firestoreValue: Any { self?.firestoreValue ?? NSNull() }
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
  public typealias Schema = FirestoreSchema<Self>

  public var firestoreValue: Any { map(\.firestoreValue) }
}
extension Array: FirestoreEquatable where Element: FirestoreEquatable {}

extension Set: FirestoreModel where Element: FirestoreModel {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { map(\.firestoreValue) }
}

extension Dictionary: FirestoreModel where Key == String, Value: FirestoreModel {
  public typealias Schema = FirestoreSchema<Self>
  public var firestoreValue: Any { mapValues(\.firestoreValue) }
}
extension Dictionary: FirestoreEquatable where Key == String, Value: FirestoreEquatable {}
