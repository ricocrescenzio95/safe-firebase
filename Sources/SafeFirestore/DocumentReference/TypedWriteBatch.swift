import FirebaseFirestore

/// A type-safe wrapper around a Firestore write batch.
///
/// A batch groups multiple writes and sends them atomically with commit().
/// The model type is carried by each TypedDocumentReference passed to the
/// write methods.
public struct TypedWriteBatch {
  /// The underlying Firebase write batch.
  let batch: WriteBatch
  
  /// Encodes and writes a complete model to a document.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - document: The typed document that receives the model.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData<Model: FirestoreModel & Encodable>(
    from model: Model,
    forDocument document: TypedDocumentReference<Model>,
    encoder: Firestore.Encoder = .init()
  ) throws {
    try batch.setData(from: model, forDocument: document.documentReference, encoder: encoder)
  }
  
  /// Encodes and writes a model, optionally merging it with existing data.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - document: The typed document that receives the model.
  ///   - merge: Whether to preserve fields not present in the encoded model.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData<Model: FirestoreModel & Encodable>(
    from model: Model,
    forDocument document: TypedDocumentReference<Model>,
    merge: Bool,
    encoder: Firestore.Encoder = .init()
  ) throws {
    try batch.setData(from: model, forDocument: document.documentReference, merge: merge, encoder: encoder)
  }
  
  /// Encodes and writes a model, merging only the specified fields.
  ///
  /// - Parameters:
  ///   - model: The model to encode and store.
  ///   - document: The typed document that receives the model.
  ///   - mergeFields: The model fields to merge.
  ///   - encoder: The encoder used to convert the model into Firestore data.
  public func setData<Model: FirestoreModel & Encodable>(
    from model: Model,
    forDocument document: TypedDocumentReference<Model>,
    mergeFields: [DocumentDataField<Model>],
    encoder: Firestore.Encoder = .init()
  ) throws {
    let fields = mergeFields.map(\.path)
    try batch.setData(
      from: model,
      forDocument: document.documentReference,
      mergeFields: fields,
      encoder: encoder
    )
  }
  
  /// Writes individual typed field values to a document.
  ///
  /// - Parameters:
  ///   - documentData: The field values to write.
  ///   - document: The typed document that receives the values.
  public func setData<Model>(
    _ documentData: [DocumentData<Model>],
    forDocument document: TypedDocumentReference<Model>
  ) {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    batch.setData(dict, forDocument: document.documentReference)
  }
  
  /// Writes individual field values, optionally merging with existing data.
  ///
  /// - Parameters:
  ///   - documentData: The field values to write.
  ///   - document: The typed document that receives the values.
  ///   - merge: Whether to preserve fields not included in documentData.
  public func setData<Model>(
    _ documentData: [DocumentData<Model>],
    forDocument document: TypedDocumentReference<Model>,
    merge: Bool
  ) {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    batch.setData(dict, forDocument: document.documentReference, merge: merge)
  }
  
  /// Writes field values and merges only the specified fields.
  ///
  /// - Parameters:
  ///   - documentData: The field values to write.
  ///   - document: The typed document that receives the values.
  ///   - mergeFields: The fields to merge.
  public func setData<Model>(
    _ documentData: [DocumentData<Model>],
    forDocument document: TypedDocumentReference<Model>,
    mergeFields: [DocumentDataField<Model>]
  ) {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    
    let fields = mergeFields.map(\.path)
    batch.setData(
      dict,
      forDocument: document.documentReference,
      mergeFields: fields
    )
  }
  
  /// Updates individual fields in an existing document.
  ///
  /// - Parameters:
  ///   - documentData: The field values to update.
  ///   - document: The typed document to update.
  public func updateData<Model>(
    _ documentData: [DocumentData<Model>],
    forDocument document: TypedDocumentReference<Model>
  ) {
    var dict = [String: Any]()
    for pair in documentData {
      dict[pair.path] = pair.value
    }
    batch.updateData(dict, forDocument: document.documentReference)
  }
  
  /// Commits the batch using Firebase's callback-based API.
  ///
  /// Prefer commit() in async code so commit failures are thrown.
  public func commit() {
    batch.commit()
  }
  
  /// Commits the batch and throws if Firebase rejects it.
  public func commit() async throws {
    try await batch.commit()
  }
  
  /// Deletes a document as part of the batch.
  ///
  /// - Parameter document: The typed document to delete.
  public func deleteDocument<Model>(_ document: TypedDocumentReference<Model>) {
    batch.deleteDocument(document.documentReference)
  }
}

/// Adds typed batch creation to Firestore.
extension Firestore {
  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// The maximum number of writes allowed in a single batch is 500, but note that each usage of
  /// ``FirestoreServerTimestamp``,  ``FirestoreArrayUnion``,  ``FirestoreArrayRemove``, or
  /// ``FirestoreIncrement`` inside a batch counts as an additional write.
  ///
  /// Unlike transactions, write batches are persisted offline and therefore are preferable when you
  /// don't need to condition your writes on read data.
  public func typedBatch() -> TypedWriteBatch {
    TypedWriteBatch(batch: batch())
  }
}
