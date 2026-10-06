import FirebaseFirestore

/// The results returned by executing a typed Firestore query.
public struct TypedQuerySnapshot<Model: FirestoreModel>: Sendable {
  /// The underlying Firebase query snapshot.
  @_documentation(visibility: internal)
  let _snapshot: QuerySnapshot
  
  /// A Boolean value indicating whether the query returned no documents.
  public var isEmpty: Bool {
    _snapshot.isEmpty
  }
  
  /// The number of documents in the result.
  public var count: Int {
    _snapshot.count
  }
  
  /// Metadata describing the source and state of the snapshot.
  public var metadata: SnapshotMetadata {
    _snapshot.metadata
  }
  
  /// The document changes included in this snapshot.
  public var documentChanges: [TypedDocumentChange<Model>] {
    _snapshot.documentChanges.lazy.map(TypedDocumentChange.init(_documentChange:))
  }
  
  /// Returns the document changes, optionally including metadata-only changes.
  ///
  /// - Parameter includeMetadataChanges: Whether metadata-only changes should be included.
  /// - Returns: The typed document changes in this snapshot.
  public func documentChanges(includeMetadataChanges: Bool) -> [TypedDocumentChange<Model>] {
    _snapshot.documentChanges(includeMetadataChanges: includeMetadataChanges)
      .lazy
      .map(TypedDocumentChange.init(_documentChange:))
  }
  
  /// The documents returned by the query.
  public let documents: [TypedQueryDocumentSnapshot<Model>]

  init(snapshot: QuerySnapshot) {
    self._snapshot = snapshot
    documents = snapshot.documents.lazy.map(TypedQueryDocumentSnapshot.init(_documentSnapshot:))
  }
}

/// A document snapshot returned as part of a typed query result.
public struct TypedQueryDocumentSnapshot<Model: FirestoreModel>: TypedDocumentSnapshotProtocol {
  /// The underlying query document snapshot.
  @_documentation(visibility: internal)
  public let _documentSnapshot: QueryDocumentSnapshot
}

/// A change to a document in a typed query snapshot.
public struct TypedDocumentChange<Model: FirestoreModel>: Sendable {
  /// The underlying Firebase document change.
  @_documentation(visibility: internal)
  public let _documentChange: DocumentChange
  
  /// The kind of change represented by this value.
  public var type: DocumentChangeType {
    _documentChange.type
  }
  
  /// The document's previous index in the result set.
  public var oldIndex: UInt {
    _documentChange.oldIndex
  }
  
  /// The document's new index in the result set.
  public var newIndex: UInt {
    _documentChange.newIndex
  }
  
  /// The document affected by the change.
  public var document: TypedQueryDocumentSnapshot<Model> {
    TypedQueryDocumentSnapshot(_documentSnapshot: _documentChange.document)
  }
}
