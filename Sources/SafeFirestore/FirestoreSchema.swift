/// The common interface implemented by generated Firestore schema values.
///
/// Schema values carry a field path and expose the model value represented by
/// that path. This protocol is primarily used by the generated schema and
/// typed query APIs.
public protocol FirestoreSchemaProtocol<Value>: Sendable {
  associatedtype Value
  var _firestorePath: [String] { get }
}

/// A schema value for a non-optional Firestore value.
///
/// Nested model members are available through dynamic member lookup, while
/// dictionary values can be selected with a string subscript.
@dynamicMemberLookup
public struct FirestoreSchema<Value>: FirestoreSchemaProtocol {
  /// The components of the Firestore field path.
  public let _firestorePath: [String]

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.Schema, Member>
  ) -> Member where Value: FirestoreModel {
    Value.schema(path: _firestorePath)[keyPath: keyPath]
  }
}

/// A schema value for an optional Firestore value.
///
/// Members of the wrapped model remain traversable, and null checks are
/// available through the typed query API.
@dynamicMemberLookup
public struct FirestoreOptionalSchema<Wrapped>: FirestoreSchemaProtocol {
  public typealias Value = Wrapped?

  public let _firestorePath: [String]

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Wrapped.Schema, Member>
  ) -> Member where Wrapped: FirestoreModel {
    Wrapped.schema(path: _firestorePath)[keyPath: keyPath]
  }
}
