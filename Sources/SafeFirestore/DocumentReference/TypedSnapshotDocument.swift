import FirebaseFirestore

/// Common interface for typed Firestore document snapshots.
///
/// Use ``TypedDocumentReference`` to obtain a snapshot:
///
/// ```swift
/// let snapshot = try await reference.getDocument()
/// let user = try snapshot.data()
/// ```
public protocol TypedDocumentSnapshotProtocol<Model, DocumentSnapshot>: Sendable, Identifiable {
  /// The model represented by the snapshot.
  associatedtype Model: FirestoreModel
  /// The underlying Firebase document snapshot type.
  associatedtype DocumentSnapshot: FirebaseFirestore::DocumentSnapshot
  
  @_documentation(visibility: internal)
  var _documentSnapshot: DocumentSnapshot { get }
}

extension TypedDocumentSnapshotProtocol {
  /// The document identifier used by Identifiable.
  public var id: String { documentID }
  
  /// The document identifier.
  public var documentID: String {
    _documentSnapshot.documentID
  }
  
  /// Metadata describing the source and state of the snapshot.
  public var metadata: SnapshotMetadata {
    _documentSnapshot.metadata
  }
  
  /// A ``TypedDocumentReference`` to the document represented by the snapshot.
  public var reference: TypedDocumentReference<Model> {
    TypedDocumentReference(documentReference: _documentSnapshot.reference)
  }
  
  /// Decodes the snapshot data as the model type.
  ///
  /// - Parameters:
  ///   - serverTimestampBehavior: How unresolved server timestamps are decoded.
  ///   - decoder: The decoder used to decode the snapshot.
  /// - Returns: The decoded model.
  public func data(
    with serverTimestampBehavior: ServerTimestampBehavior = .none,
    decoder: Firestore.Decoder = .init()
  ) throws -> Model where Model: Decodable {
    try _documentSnapshot.data(as: Model.self, with: serverTimestampBehavior, decoder: decoder)
  }
  
  /// Reads a value at a typed field path.
  ///
  /// - Parameters:
  ///   - field: The field path to read.
  ///   - serverTimestampBehavior: How unresolved server timestamps are handled.
  /// - Returns: The value at the path, cast to the requested type.
  public func get<T>(
    _ field: DocumentDataField<Model>,
    serverTimestampBehavior: ServerTimestampBehavior = .none
  ) -> T? {
    _documentSnapshot.get(field.path, serverTimestampBehavior: serverTimestampBehavior) as? T
  }
}

/// A typed snapshot of a Firestore document.
public struct TypedDocumentSnapshot<Model: FirestoreModel>: TypedDocumentSnapshotProtocol {
  @_documentation(visibility: internal)
  public let _documentSnapshot: DocumentSnapshot
  
  /// A Boolean value indicating whether the document exists.
  public var exists: Bool {
    _documentSnapshot.exists
  }
}
