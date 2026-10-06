import FirebaseFirestore

/// A type-safe reference to a Firestore document.
///
/// ```swift
/// let reference = Firestore.firestore()
///     .collection(User.self)
///     .document("user-123")
///
/// let user = try await reference.getDataDocument()
/// ```
public struct TypedDocumentReference<Model: FirestoreModel>: Sendable {
  /// The underlying Firebase document reference.
  let documentReference: DocumentReference
  
  /// The document identifier.
  public var documentID: String {
    documentReference.documentID
  }
  
  /// The complete path of the document.
  public var path: String {
    documentReference.path
  }
  
  /// The `Firestore` database that owns the document.
  public var firestore: Firestore {
    documentReference.firestore
  }
  
  /// Returns the typed parent collection.
  ///
  /// - Parameter type: The model type of documents in the parent collection.
  /// - Returns: The parent collection reference.
  public func parent<Parent>(_ type: Parent.Type) -> TypedCollectionReference<Parent>? {
    TypedCollectionReference(collectionReference: documentReference.parent)
  }
  
  /// Returns a typed subcollection reference.
  ///
  /// - Parameter type: The model associated with the subcollection.
  /// - Returns: A typed subcollection reference.
  public func collection<NewModel: FirestoreCollection>(_: NewModel.Type) -> TypedCollectionReference<NewModel> {
    TypedCollectionReference(
      collectionReference: documentReference
        .collection(NewModel.collectionName)
    )
  }
  
  /// Replaces the document with an encoded model.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData(
    from model: Model,
    encoder: Firestore.Encoder = .init()
  ) async throws where Model: Encodable {
    try await documentReference.setData(from: model, encoder: encoder)
  }
  
  /// Writes an encoded model, optionally merging it with the existing document.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - merge: Whether to merge the encoded fields with existing data.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData(
    from model: Model,
    merge: Bool,
    encoder: Firestore.Encoder = .init()
  ) async throws where Model: Encodable {
    try await documentReference.setData(from: model, merge: merge, encoder: encoder)
  }
  
  /// Writes an encoded model and merges only the specified fields.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - mergeFields: The model fields that should be merged.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData(
    from model: Model,
    mergeFields: [DocumentDataField<Model>],
    encoder: Firestore.Encoder = .init()
  ) async throws where Model: Encodable {
    var fields = [String]()
    for pair in mergeFields {
      fields.append(pair.path)
    }
    
    try await documentReference.setData(
      from: model,
      mergeFields: fields,
      encoder: encoder
    )
  }
  
  /// Writes individual field values to the document.
  ///
  /// - Parameter documentData: The field values to write.
  public func setData(_ documentData: [DocumentData<Model>]) async throws {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    try await documentReference.setData(dict)
  }
  
  /// Writes individual field values, optionally merging with existing data.
  ///
  /// - Parameters:
  ///   - documentData: The field values to write.
  ///   - merge: Whether to preserve fields not included in documentData.
  public func setData(_ documentData: [DocumentData<Model>], merge: Bool) async throws {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    try await documentReference.setData(dict, merge: merge)
  }
  
  /// Writes field values and merges only the specified fields.
  ///
  /// - Parameters:
  ///   - documentData: The field values to write.
  ///   - mergeFields: The fields that should be merged.
  public func setData(
    _ documentData: [DocumentData<Model>],
    mergeFields: [DocumentDataField<Model>],
  ) async throws {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    
    var fields = [String]()
    for pair in mergeFields {
      fields.append(pair.path)
    }
    
    try await documentReference.setData(
      dict,
      mergeFields: fields
    )
  }
  
  /// Updates individual fields in an existing document.
  ///
  /// - Parameter documentData: The field values to update.
  public func updateData(_ documentData: [DocumentData<Model>]) async throws {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    try await documentReference.updateData(dict)
  }

  /// Deletes the document asynchronously.
  public func delete() async throws {
    try await documentReference.delete()
  }
  
  /// Deletes the document using the Firebase callback-based API.
  public func delete() {
    documentReference.delete()
  }
  
  /// Fetches the document as a typed snapshot.
  ///
  /// - Parameter source: The source from which to read the document.
  /// - Returns: The typed document snapshot.
  public func getDocument(source: FirestoreSource = .default) async throws -> TypedDocumentSnapshot<Model> {
    try await TypedDocumentSnapshot(_documentSnapshot: documentReference.getDocument(source: source))
  }
  
  /// Fetches and decodes the document as the model type.
  ///
  /// - Parameters:
  ///   - serverTimestampBehavior: How unresolved server timestamps are decoded.
  ///   - decoder: The decoder used to decode the document.
  ///   - source: The source from which to read the document.
  /// - Returns: The decoded model.
  public func getDataDocument(
    with serverTimestampBehavior: ServerTimestampBehavior = .none,
    decoder: Firestore.Decoder = Firestore.Decoder(),
    source: FirestoreSource = .default
  ) async throws -> Model where Model: Decodable {
    try await documentReference.getDocument(
      as: Model.self,
      with: serverTimestampBehavior,
      decoder: decoder,
      source: source
    )
  }
}
