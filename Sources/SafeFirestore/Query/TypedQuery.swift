import FirebaseFirestore

/// A type-safe Firestore query for a model.
///
/// ```swift
/// let query = Firestore.firestore()
///     .collection(User.self)
///     .where { $0.active == true }
///     .order(by: { $0.createdAt })
///     .limit(to: 20)
/// ```
public protocol TypedQueryProtocol<Model>: Sendable {
  /// The model returned by this query.
  associatedtype Model: FirestoreModel
  
  @_documentation(visibility: internal)
  var _query: Query { get }
}

/// A concrete typed query that can be progressively configured.
public struct TypedQuery<Model: FirestoreModel>: TypedQueryProtocol {
  /// The underlying Firebase query.
  @_documentation(visibility: internal)
  public let _query: Query
}

public extension TypedQueryProtocol {
  /// Filters documents using a type-safe predicate.
  ///
  /// - Parameter predicate: A closure that builds a predicate from the model schema.
  /// - Returns: A query containing the requested filter.
  func `where`(_ predicate: (Model.Schema) throws -> some FirestorePredicateExpression) rethrows -> TypedQuery<Model> {
    let resolved = try predicate(Model.schema(path: []))
    let filter = resolved.makeFilter()
    return TypedQuery(_query: _query.whereFilter(filter))
  }
  
  // MARK: - Order
  
  /// Orders documents by a model field in ascending order.
  ///
  /// - Parameters:
  ///   - predicate: A closure selecting the field used for ordering.
  ///   - descending: Whether to sort descending.
  /// - Returns: A query containing the ordering constraint.
  func order<T: FirestoreModel>(by predicate: (Model.Schema) -> FirestoreSchema<T>, descending: Bool = false) -> TypedQuery<Model> {
    let path = predicate(Model.schema(path: []))._firestorePath
    return TypedQuery(_query: _query.order(by: FieldPath(path), descending: descending))
  }
  
  /// Orders documents by a model field in ascending order.
  ///
  /// - Parameters:
  ///   - predicate: A closure selecting the field used for ordering.
  ///   - descending: Whether to sort descending.
  /// - Returns: A query containing the ordering constraint.
  func order<T: FirestoreModel>(by predicate: (Model.Schema) -> FirestoreOptionalSchema<T>, descending: Bool = false) -> TypedQuery<Model> {
    let path = predicate(Model.schema(path: []))._firestorePath
    return TypedQuery(_query: _query.order(by: FieldPath(path), descending: descending))
  }
  
  // MARK: - Limit
  
  /// Limits the query to at most the specified number of documents.
  ///
  /// - Parameter count: The maximum number of documents to return.
  /// - Returns: A query with the limit applied.
  func limit(to count: Int) -> TypedQuery<Model> {
    TypedQuery(_query: _query.limit(to: count))
  }
  
  /// Limits the query to the last documents in its ordering.
  ///
  /// - Parameter count: The maximum number of documents to return.
  /// - Returns: A query with the limit-to-last constraint applied.
  func limit(toLast count: Int) -> TypedQuery<Model> {
    TypedQuery(_query: _query.limit(toLast: count))
  }
  
  // MARK: - Pagination (start/end)
  
  /// Starts the result set at the supplied field values.
  func start(at values: [Any]) -> TypedQuery<Model> {
    TypedQuery(_query: _query.start(at: values))
  }
  
  /// Starts the result set after the supplied field values.
  func start(after values: [Any]) -> TypedQuery<Model> {
    TypedQuery(_query: _query.start(after: values))
  }
  
  /// Ends the result set at the supplied field values.
  func end(at values: [Any]) -> TypedQuery<Model> {
    TypedQuery(_query: _query.end(at: values))
  }
  
  /// Ends the result set before the supplied field values.
  func end(before values: [Any]) -> TypedQuery<Model> {
    TypedQuery(_query: _query.end(before: values))
  }
  
  // DocumentSnapshot variants
  
  /// Starts the result set at the supplied document snapshot.
  func start(atDocument snapshot: TypedDocumentSnapshot<Model>) -> TypedQuery<Model> {
    TypedQuery(_query: _query.start(atDocument: snapshot._documentSnapshot))
  }
  
  /// Starts the result set after the supplied document snapshot.
  func start(afterDocument snapshot: TypedDocumentSnapshot<Model>) -> TypedQuery<Model> {
    TypedQuery(_query: _query.start(afterDocument: snapshot._documentSnapshot))
  }
  
  /// Ends the result set at the supplied document snapshot.
  func end(atDocument snapshot: TypedDocumentSnapshot<Model>) -> TypedQuery<Model> {
    TypedQuery(_query: _query.end(atDocument: snapshot._documentSnapshot))
  }
  
  /// Ends the result set before the supplied document snapshot.
  func end(beforeDocument snapshot: TypedDocumentSnapshot<Model>) -> TypedQuery<Model> {
    TypedQuery(_query: _query.end(beforeDocument: snapshot._documentSnapshot))
  }
  
  // MARK: - Aggregations
  
  /// Creates an aggregation query that counts the documents matching this query.
  var count: TypedAggregateQuery<Model> {
    TypedAggregateQuery(_query: _query.count)
  }
  
  /// Creates an aggregation query from the requested aggregate fields.
  ///
  /// Use type-preserving fields such as
  /// TypedAggregateField<Model, Int>.sum(.value) when reading the result.
  func aggregate(_ aggregateFields: [AnyTypedAggregateField<Model>]) -> TypedAggregateQuery<Model> {
    TypedAggregateQuery(_query: _query.aggregate(aggregateFields.map(\.aggregateField)))
  }
  
  // MARK: - Get snapshots
  
  /// Executes the query and decodes its documents as the model type.
  ///
  /// - Parameter source: The source from which to read the documents.
  /// - Returns: A typed query snapshot.
  func getDocuments(source: FirestoreSource = .default) async throws -> TypedQuerySnapshot<Model> where Model: Decodable {
    try await TypedQuerySnapshot(snapshot: _query.getDocuments(source: source))
  }
}

public struct TypedAggregateQuery<Model: FirestoreModel> {
  /// The underlying Firebase query.
  @_documentation(visibility: internal)
  public let _query: AggregateQuery
  
  /// Executes the aggregation query and returns its typed snapshot.
  ///
  /// - Parameter source: The source from which Firestore should read the result.
  /// - Returns: A snapshot containing the requested aggregate values.
  public func getAggregation(source: AggregateSource = .server) async throws -> TypedAggregateQuerySnapshot<Model> {
    try await TypedAggregateQuerySnapshot(_snapshot: _query.getAggregation(source: source))
  }
}
