import Foundation
import FirebaseFirestore

/// A type-erased value that can be stored in Cloud Firestore.
///
/// Use AnyFirestoreModel when a value's concrete Swift type is not known at
/// compile time, such as when inspecting arbitrary document data or building
/// dynamic updates. The enum preserves the Firestore value kind and can be
/// encoded and decoded with Codable.
///
/// The firestoreValue property converts the value to the representation
/// accepted by the Firebase Firestore SDK.
public enum AnyFirestoreModel:
    FirestoreModel,
    FirestoreEquatable,
    FirestoreComparable,
    FirestoreArraySchemaValue,
    FirestoreArrayMembershipSchemaValue,
    FirestoreSetSchemaValue,
    FirestoreMapSchemaValue,
    Hashable
{  
  /// The schema type associated with an arbitrary Firestore value.
  public typealias Schema = FirestoreSchema<Self>

  /// The element type used by collection schema conformances.
  public typealias Element = AnyFirestoreModel

  /// A Firestore null value.
  case null

  /// A Boolean value.
  case bool(Bool)

  /// A signed 64-bit integer value.
  case int(Int64)

  /// A double-precision floating-point value.
  case double(Double)

  /// A UTF-8 string value.
  case string(String)

  /// A Firestore timestamp value.
  case timestamp(Timestamp)

  /// A Foundation date value.
  case date(Date)

  /// A geographic point.
  case geoPoint(GeoPoint)

  /// A reference to a Firestore document.
  case documentReference(DocumentReference)

  /// Binary data.
  case data(Data)

  /// An ordered collection of Firestore values.
  case array([AnyFirestoreModel])

  /// A dictionary whose keys are Firestore field names.
  case map([String: AnyFirestoreModel])

  /// The value converted to a type accepted by the Firebase Firestore SDK.
  public var firestoreValue: Any {
    switch self {
    case .null: NSNull()
    case let .bool(v): v.firestoreValue
    case let .int(v): v.firestoreValue
    case let .double(v): v.firestoreValue
    case let .string(v): v.firestoreValue
    case let .timestamp(v): v.firestoreValue
    case let .date(v): v.firestoreValue
    case let .geoPoint(v): v.firestoreValue
    case let .documentReference(v): v.firestoreValue
    case let .data(v): v.firestoreValue
    case let .array(v): v.map(\.firestoreValue)
    case let .map(v): v.mapValues(\.firestoreValue)
    }
  }

  /// Creates a value by decoding one of the supported Firestore types.
  ///
  /// Decoding attempts the cases in the order used by this type: null,
  /// Boolean, integer, double, string, timestamp, date, geographic point,
  /// document reference, data, array, and map.
  ///
  /// - Parameter decoder: The decoder from which to read the value.
  /// - Throws: A decoding error when the input cannot be represented as a
  ///   Firestore value.
  public init(from decoder: any Decoder) throws {
    let c = try decoder.singleValueContainer()

    if c.decodeNil() { self = .null }
    else if let v = try? c.decode(Bool.self) { self = .bool(v) }
    else if let v = try? c.decode(Int64.self) { self = .int(v) }
    else if let v = try? c.decode(Double.self) { self = .double(v) }
    else if let v = try? c.decode(String.self) { self = .string(v) }
    else if let v = try? c.decode(Timestamp.self) { self = .timestamp(v) }
    else if let v = try? c.decode(Date.self) { self = .date(v) }
    else if let v = try? c.decode(GeoPoint.self) { self = .geoPoint(v) }
    else if let v = try? c.decode(DocumentReference.self) { self = .documentReference(v) }
    else if let v = try? c.decode(Data.self) { self = .data(v) }
    else if let v = try? c.decode([AnyFirestoreModel].self) { self = .array(v) }
    else if let v = try? c.decode([String: AnyFirestoreModel].self) { self = .map(v) }
    else {
      throw DecodingError.dataCorruptedError(
        in: c,
        debugDescription: "The value cannot be represented as a Firestore value."
      )
    }
  }

  /// Encodes the value using its corresponding Firestore value kind.
  ///
  /// - Parameter encoder: The encoder to which to write the value.
  /// - Throws: An encoding error when the value cannot be written.
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .null: try c.encodeNil()
    case let .bool(v): try c.encode(v)
    case let .int(v): try c.encode(v)
    case let .double(v): try c.encode(v)
    case let .string(v): try c.encode(v)
    case let .timestamp(v): try c.encode(v)
    case let .date(v): try c.encode(v)
    case let .geoPoint(v): try c.encode(v)
    case let .documentReference(v): try c.encode(v)
    case let .data(v): try c.encode(v)
    case let .array(v): try c.encode(v)
    case let .map(v): try c.encode(v)
    }
  }

  /// Whether the value is Firestore null.
  public var isNull: Bool {
    self == .null
  }

  /// The Boolean value, or nil when this value is not a Boolean.
  public var bool: Bool? {
    guard case .bool(let value) = self else { return nil }
    return value
  }

  /// The integer value, or nil when this value is not an integer.
  public var int: Int64? {
    guard case .int(let value) = self else { return nil }
    return value
  }

  /// The double value, or nil when this value is not a double.
  public var double: Double? {
    guard case .double(let value) = self else { return nil }
    return value
  }

  /// The string value, or nil when this value is not a string.
  public var string: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  /// The timestamp value, or nil when this value is not a timestamp.
  public var timestamp: Timestamp? {
    guard case .timestamp(let value) = self else { return nil }
    return value
  }

  /// The date value, or nil when this value is not a date.
  public var date: Date? {
    guard case .date(let value) = self else { return nil }
    return value
  }

  /// The geographic point, or nil when this value is not a geographic point.
  public var geoPoint: GeoPoint? {
    guard case .geoPoint(let value) = self else { return nil }
    return value
  }

  /// The document reference, or nil when this value is not a document reference.
  public var documentReference: DocumentReference? {
    guard case .documentReference(let value) = self else { return nil }
    return value
  }

  /// The binary data, or nil when this value is not binary data.
  public var data: Data? {
    guard case .data(let value) = self else { return nil }
    return value
  }

  /// The array value, or nil when this value is not an array.
  public var array: [AnyFirestoreModel]? {
    guard case .array(let value) = self else { return nil }
    return value
  }

  /// The map value, or nil when this value is not a map.
  public var map: [String: AnyFirestoreModel]? {
    guard case .map(let value) = self else { return nil }
    return value
  }
}
