import FirebaseFirestore

/// A type-safe wrapper around a Firestore transaction.
///
/// A transaction may be retried by Firebase. Keep the update closure free of
/// external side effects and perform reads before writes.
public struct TypedTransaction {
  /// The underlying Firebase transaction.
  let transaction: Transaction
  
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
    try transaction.setData(from: model, forDocument: document.documentReference, encoder: encoder)
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
    try transaction.setData(from: model, forDocument: document.documentReference, merge: merge, encoder: encoder)
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
    try transaction.setData(
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
    transaction.setData(dict, forDocument: document.documentReference)
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
    transaction.setData(dict, forDocument: document.documentReference, merge: merge)
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
    transaction.setData(
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
    transaction.updateData(dict, forDocument: document.documentReference)
  }
  
  /// Reads a document in the current transaction.
  ///
  /// All reads in a transaction should happen before writes.
  ///
  /// - Parameter document: The typed document to read.
  /// - Returns: A typed snapshot for the document.
  public func getDocument<Model>(
    _ document: TypedDocumentReference<Model>
  ) throws -> TypedDocumentSnapshot<Model> {
    try TypedDocumentSnapshot(
      _documentSnapshot: transaction.getDocument(document.documentReference)
    )
  }
  
  /// Deletes a document as part of the transaction.
  ///
  /// - Parameter document: The typed document to delete.
  public func deleteDocument<Model>(_ document: TypedDocumentReference<Model>) {
    transaction.deleteDocument(document.documentReference)
  }
}

extension Firestore {
  /// Executes the closure and attempts to commit its changes atomically.
  ///
  /// A transaction supports typed reads and writes through the
  /// ``TypedTransaction`` value passed to the closure. Firestore retries the
  /// closure when data read by the transaction changes before the commit.
  ///
  /// A transaction can contain at most 500 writes. Each use of a server-side
  /// transform such as ``FirestoreServerTimestamp``, ``FirestoreArrayUnion``,
  /// ``FirestoreArrayRemove``, or ``FirestoreIncrement`` counts as an
  /// additional write.
  ///
  /// If `TransactionOptions` is nil, Firebase uses its default options,
  /// including a maximum of five attempts. The transaction must be performed
  /// while the client is online; reads and the final commit fail otherwise.
  ///
  /// The closure may be invoked multiple times, so it must not perform
  /// irreversible side effects or mutate unrelated application state. All
  /// reads must be completed before any writes. Transaction reads do not
  /// include local changes that have not been committed.
  ///
  /// If the closure throws, the transaction stops and the error is propagated
  /// to the caller. When Firebase cannot commit the transaction, that error is
  /// also thrown.
  ///
  /// - Parameters:
  ///   - options: Options controlling transaction execution, or nil to use
  ///     Firebase's defaults.
  ///   - updateBlock: A throwing closure that performs typed reads and writes.
  /// - Returns: The value returned by updateBlock after a successful commit.
  /// - Throws: An error raised by updateBlock, or an error returned by
  ///   Firebase when the transaction cannot be committed.
  public func runTypedTransaction<Result>(
    with options: TransactionOptions? = nil,
    _ updateBlock: @escaping (TypedTransaction) throws -> sending Result
  ) async throws -> sending Result {
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Result, Error>) in
      runTransaction(
        with: options,
        block: { transaction, errorPointer in
          do {
            return try updateBlock(
              TypedTransaction(transaction: transaction)
            )
          } catch {
            errorPointer?.pointee = error as NSError
            return nil
          }
        },
        completion: { result, error in
          if let error {
            continuation.resume(throwing: error)
          } else if let result = result as? Result {
            // value is ok to be sent as the internal implementation itself
            // is sending the value
            nonisolated(unsafe) let result = result
            continuation.resume(returning: result)
          } else {
            continuation.resume(throwing: TypedTransactionError.missingResult)
          }
        }
      )
    }
  }
}

/// An error produced by a typed transaction wrapper.
public enum TypedTransactionError: Error {
  /// Firebase completed a transaction without returning the requested value.
  case missingResult
}
