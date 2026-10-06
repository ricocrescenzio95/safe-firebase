import FirebaseFirestore

/// A type-safe reference to a Firestore collection.
///
/// The reference also acts as a query and supports filtering, ordering,
/// pagination, and document creation.
///
/// ```swift
/// let users = Firestore.firestore().collection(User.self)
/// let reference = users.document("user-123")
/// let adults = users.where { $0.age >= 18 }
/// ```
public struct TypedCollectionReference<Model: FirestoreModel>: Sendable, TypedQueryProtocol {
  @_documentation(visibility: internal)
  public var _query: Query { collectionReference }
  let collectionReference: CollectionReference
  
  /// The final component of the collection path.
  public var collectionID: String {
    collectionReference.collectionID
  }
  
  /// The complete path of the collection.
  public var path: String {
    collectionReference.path
  }
  
  /// The `Firestore` database that owns the collection.
  public var firestore: Firestore {
    collectionReference.firestore
  }
  
  /// Returns the typed parent document, when this collection is nested.
  ///
  /// - Parameter type: The model type of the parent document.
  /// - Returns: The parent document reference, or nil for a top-level collection.
  public func parent<Parent>(_ type: Parent.Type) -> TypedDocumentReference<Parent>? {
    collectionReference.parent.map {
      TypedDocumentReference(documentReference: $0)
    }
  }
  
  /// Adds a document using the Firestore encoder.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func addDocument(
    from model: Model,
    encoder: Firestore.Encoder = Firestore.Encoder()
  ) throws -> TypedDocumentReference<Model> where Model: Encodable {
    try TypedDocumentReference(documentReference: collectionReference.addDocument(from: model, encoder: encoder))
  }
  
  /// Adds a document using the Firestore encoder.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func addDocument(
    from model: Model,
    encoder: Firestore.Encoder = Firestore.Encoder()
  ) async throws -> TypedDocumentReference<Model> where Model: Encodable {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TypedDocumentReference<Model>, any Error>) in
      do {
        var document: DocumentReference?
        document = try collectionReference.addDocument(from: model, encoder: encoder) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: TypedDocumentReference(documentReference: document!))
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
  
  /// Creates a reference to a new document with an automatically generated ID.
  public func document() -> TypedDocumentReference<Model> {
    TypedDocumentReference(documentReference: collectionReference.document())
  }

  /// Creates a reference to a document at the specified path.
  ///
  /// - Parameter documentPath: A document path relative to this collection.
  public func document(_ documentPath: String) -> TypedDocumentReference<Model> {
    TypedDocumentReference(documentReference: collectionReference.document(documentPath))
  }
}

extension Firestore {
  /// Returns a typed reference to the collection associated with a model.
  ///
  /// - Parameter type: The model whose collection name should be used.
  /// - Returns: A typed collection reference.
  public func collection<Model: FirestoreCollection>(_: Model.Type) -> TypedCollectionReference<Model> {
    TypedCollectionReference(collectionReference: collection(Model.collectionName))
  }
  
  /// Creates and returns a new ``TypedQuery`` that includes all documents in the database that are contained
  /// in a collection or subcollection with the given collection model type.
  ///
  /// - Parameter type: Identifies the collections to query over. Every collection or subcollection
  ///     with this ID as the last segment of its path will be included. Cannot contain a slash.
  /// - Returns: The created `Query`.
  public func collectionGroup<Model: FirestoreCollection>(_: Model.Type) -> TypedQuery<Model> {
    TypedQuery(_query: collectionGroup(Model.collectionName))
  }
}
