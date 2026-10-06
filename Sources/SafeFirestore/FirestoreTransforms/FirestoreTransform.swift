import Foundation
import FirebaseFirestore

/// A typed Firestore server-side transform for a model field.
///
/// The associated `Value` is the field type the transform targets.
public protocol FirestoreTransform<Value> {
  associatedtype Value
  var firestoreValue: FieldValue { get }
}

// MARK: - Server timestamp

/// A field value that can receive a server timestamp.
public protocol FirestoreServerTimestampValue {}
extension Date: FirestoreServerTimestampValue {}
extension Optional: FirestoreServerTimestampValue where Wrapped: FirestoreServerTimestampValue {}

/// Replaces a field with the timestamp assigned by the Firestore server.
///
/// Use `FirestoreServerTimestamp<Date>()` for a `Date` field or
/// `FirestoreServerTimestamp<Date?>()` for an optional `Date` field.
public struct FirestoreServerTimestamp<DateType: FirestoreServerTimestampValue>: FirestoreTransform<DateType>, Sendable, Hashable {
  public var firestoreValue: FieldValue { .serverTimestamp() }
  
  public init() {}
}

// MARK: - Increment

/// A numeric field supported by Firestore numeric transforms.
public protocol FirestoreTransformNumberValue {}
extension Double: FirestoreTransformNumberValue {}
extension Float: FirestoreTransformNumberValue {}
extension Float16: FirestoreTransformNumberValue {}
extension Int: FirestoreTransformNumberValue {}
extension Int8: FirestoreTransformNumberValue {}
extension Int16: FirestoreTransformNumberValue {}
extension Int32: FirestoreTransformNumberValue {}
extension Int64: FirestoreTransformNumberValue {}
extension Optional: FirestoreTransformNumberValue where Wrapped: FirestoreTransformNumberValue {}

/// Atomically adds a numeric value to the current Firestore field.
public struct FirestoreIncrement<Value: FirestoreTransformNumberValue>: FirestoreTransform<Value>, Sendable, Hashable {
  public enum InternalValue: Sendable, Hashable {
    case double(Double)
    case int64(Int64)
  }
  public let value: InternalValue
  
  public var firestoreValue: FieldValue {
    switch value {
    case .double(let value): .increment(value)
    case .int64(let value): .increment(value)
    }
  }
  
  public init(_ value: Double) where Value == Double { self.value = .double(value) }
  public init(_ value: Float) where Value == Float { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16 { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8 { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16 { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32 { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64 { self.value = .int64(Int64(value)) }
  
  public init(_ value: Double) where Value == Double? { self.value = .double(value) }
  public init(_ value: Float) where Value == Float? { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16? { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int? { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8? { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16? { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32? { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64? { self.value = .int64(value) }
}

// MARK: - Maximum

/// Replaces the current numeric value only when the supplied value is greater.
public struct FirestoreMaximum<Value: FirestoreTransformNumberValue>: FirestoreTransform<Value>, Sendable, Hashable {
  public enum InternalValue: Sendable, Hashable {
    case double(Double)
    case int64(Int64)
  }
  public let value: InternalValue
  
  public var firestoreValue: FieldValue {
    switch value {
    case .double(let value): .maximum(value)
    case .int64(let value): .maximum(value)
    }
  }
  
  public init(_ value: Double) where Value == Double { self.value = .double(value) }
  public init(_ value: Float) where Value == Float { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16 { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8 { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16 { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32 { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64 { self.value = .int64(Int64(value)) }
  
  public init(_ value: Double) where Value == Double? { self.value = .double(value) }
  public init(_ value: Float) where Value == Float? { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16? { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int? { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8? { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16? { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32? { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64? { self.value = .int64(value) }
}

// MARK: - Minimum

/// Replaces the current numeric value only when the supplied value is smaller.
public struct FirestoreMinimum<Value: FirestoreTransformNumberValue>: FirestoreTransform<Value>, Sendable, Hashable {
  public enum InternalValue: Sendable, Hashable {
    case double(Double)
    case int64(Int64)
  }
  public let value: InternalValue
  
  public var firestoreValue: FieldValue {
    switch value {
    case .double(let value): .minimum(value)
    case .int64(let value): .minimum(value)
    }
  }
  
  public init(_ value: Double) where Value == Double { self.value = .double(value) }
  public init(_ value: Float) where Value == Float { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16 { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8 { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16 { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32 { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64 { self.value = .int64(Int64(value)) }
  
  public init(_ value: Double) where Value == Double? { self.value = .double(value) }
  public init(_ value: Float) where Value == Float? { self.value = .double(Double(value)) }
  public init(_ value: Float16) where Value == Float16? { self.value = .double(Double(value)) }
  
  public init(_ value: Int) where Value == Int? { self.value = .int64(Int64(value)) }
  public init(_ value: Int8) where Value == Int8? { self.value = .int64(Int64(value)) }
  public init(_ value: Int16) where Value == Int16? { self.value = .int64(Int64(value)) }
  public init(_ value: Int32) where Value == Int32? { self.value = .int64(Int64(value)) }
  public init(_ value: Int64) where Value == Int64? { self.value = .int64(value) }
}

// MARK: - Array Union

/// A collection field that supports array union and removal transforms.
public protocol FirestoreArrayUnionValue {
  associatedtype Element: FirestoreModel
}
extension Array: FirestoreArrayUnionValue where Element: FirestoreModel {}
extension Set: FirestoreArrayUnionValue where Element: FirestoreModel {}
extension Optional: FirestoreArrayUnionValue where Wrapped: FirestoreArrayUnionValue {
  public typealias Element = Wrapped.Element
}

/// Adds values to an array or set field without duplicating existing elements.
public struct FirestoreArrayUnion<Values: FirestoreArrayUnionValue>: FirestoreTransform<Values> {
  public let values: [Values.Element]
  public var firestoreValue: FieldValue { .arrayUnion(values) }
  
  public init(_ values: [Values.Element]) {
    self.values = values
  }
  
  @_disfavoredOverload
  public init<Element>(_ values: [Element]) where Values == [Element] {
    self.values = values
  }
}

extension FirestoreArrayUnion: Sendable where Values.Element: Sendable {}
extension FirestoreArrayUnion: Equatable where Values.Element: Equatable {}
extension FirestoreArrayUnion: Hashable where Values.Element: Hashable {}

// MARK: - Array Remove

/// Removes values from an array or set field.
public struct FirestoreArrayRemove<Values: FirestoreArrayUnionValue>: FirestoreTransform<Values> {
  public let values: [Values.Element]
  public var firestoreValue: FieldValue { .arrayRemove(values) }
  
  public init(_ values: [Values.Element]) {
    self.values = values
  }
  
  @_disfavoredOverload
  public init<Element>(_ values: [Element]) where Values == [Element] {
    self.values = values
  }
}

extension FirestoreArrayRemove: Sendable where Values.Element: Sendable {}
extension FirestoreArrayRemove: Equatable where Values.Element: Equatable {}
extension FirestoreArrayRemove: Hashable where Values.Element: Hashable {}

// MARK: - Delete

/// Deletes an optional field from the document.
public struct FirestoreDelete<Value: FirestoreOptional>: FirestoreTransform, Sendable, Hashable {
  public var firestoreValue: FieldValue { .delete() }
  
  public init() {}
}
