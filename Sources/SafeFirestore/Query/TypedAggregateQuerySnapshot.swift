import FirebaseFirestore

/// A model value that can be decoded from a numeric Firestore aggregation result.
public protocol TypedAggregateValue: FirestoreModel {
  /// Converts the numeric value returned by the Firebase SDK.
  static func from(_ nsNumber: NSNumber) -> Self
}

extension Int: TypedAggregateValue {
  public static func from(_ nsNumber: NSNumber) -> Self { nsNumber.intValue }
}
extension Double: TypedAggregateValue {
  public static func from(_ nsNumber: NSNumber) -> Self { nsNumber.doubleValue }
}

/// A typed aggregation field whose result type is known at compile time.
public struct TypedAggregateField<Model: FirestoreModel, ReturnValue: TypedAggregateValue>: Sendable {
  /// The underlying Firebase aggregation field.
  let aggregateField: AggregateField
}

/// A type-erased aggregation field used when composing an aggregation query.
public struct AnyTypedAggregateField<Model: FirestoreModel>: Sendable {
  /// The underlying Firebase aggregation field.
  let aggregateField: AggregateField
}

extension TypedAggregateField where ReturnValue == Int {
  /// Creates a document count aggregation.
  ///
  /// The result of count is always an integer.
  public static func count() -> Self {
    .init(aggregateField: .count())
  }
}
  
extension AnyTypedAggregateField {
  /// Creates a type-erased document count aggregation.
  public static func count() -> Self {
    .init(aggregateField: .count())
  }
  
  public static func sum<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreSchema<T>) -> Self {
    .init(aggregateField: .sum(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
  
  public static func sum<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>) -> Self {
    .init(aggregateField: .sum(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
  
  public static func average<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreSchema<T>) -> Self {
    .init(aggregateField: .average(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
  
  /// Creates a typed average aggregation for an optional field.
  public static func average<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>) -> Self {
    .init(aggregateField: .average(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
}

extension TypedAggregateField {
  /// Creates a sum aggregation whose result type matches the selected field.
  ///
  /// Summing an Int field produces an Int result type, while summing a
  /// Double field produces a Double result type.
  public static func sum<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreSchema<T>) -> TypedAggregateField<Model, T> {
    .init(aggregateField: .sum(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
  
  /// Creates a sum aggregation whose result type matches the wrapped value
  /// type of the selected optional field.
  public static func sum<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>) -> TypedAggregateField<Model, T> {
    .init(aggregateField: .sum(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
}

extension TypedAggregateField where ReturnValue == Double {
  /// Creates a typed average aggregation.
  ///
  /// Firestore returns averages as Double.
  public static func average<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreSchema<T>) -> Self {
    .init(aggregateField: .average(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
  
  public static func average<T: TypedAggregateValue>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>) -> Self {
    .init(aggregateField: .average(FieldPath(field(Model.schema(path: []))._firestorePath)))
  }
}

public struct TypedAggregateQuerySnapshot<Model: FirestoreModel>: Sendable {
  @_documentation(visibility: internal)
  let _snapshot: AggregateQuerySnapshot
  
  public var count: Int { _snapshot.count.intValue }
  
  public var query: TypedAggregateQuery<Model> { .init(_query: _snapshot.query) }

  /// Returns the requested aggregate value decoded as an integer.
  public func get(_ aggregateField: TypedAggregateField<Model, Int>) -> Int? {
    getValue(aggregateField)
  }

  /// Returns the requested aggregate value decoded as a double.
  public func get(_ aggregateField: TypedAggregateField<Model, Double>) -> Double? {
    getValue(aggregateField)
  }

  private func getValue<T>(_ aggregateField: TypedAggregateField<Model, T>) -> T?
  where T: TypedAggregateValue {
    let number = _snapshot.get(aggregateField.aggregateField)
    return (number as? NSNumber).map(T.from)
  }
}
