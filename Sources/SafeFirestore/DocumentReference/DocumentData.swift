import FirebaseFirestore

/// A typed field value used for direct document writes and updates.
///
/// ```swift
/// let update: DocumentData<User> = .init(\.displayName, "Ada")
/// try await reference.updateData([update])
/// ```
public struct DocumentData<Model: FirestoreModel> {
  /// The dot-separated Firestore field path.
  public let path: String
  /// The value passed to the Firestore SDK.
  public let value: Any
  
  /// Creates a field value for a scalar or single Firestore value.
  @_disfavoredOverload
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreSchema<T>, _ value: T) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.firestoreValue
  }
  
  /// Creates a field value for a scalar or single Firestore value.
  @_disfavoredOverload
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>, _ value: T) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.firestoreValue
  }
  
  /// Creates a field value for a scalar or single Firestore value.
  @_disfavoredOverload
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>, _ value: T?) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.firestoreValue
  }
  
  /// Creates a field value for an array field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreSchema<[T]>, _ value: [T]) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.map(\.firestoreValue)
  }

  /// Creates a field value for an optional array field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<[T]>, _ value: [T]) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.map(\.firestoreValue)
  }
  
  
  /// Creates a field value for an optional array field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<[T]>, _ value: [T]?) {
    self.path = DocumentDataField<Model>(field).path
    self.value = if let value {
      value.map(\.firestoreValue)
    } else {
      NSNull()
    }
  }
  
  /// Creates a field value for a set field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreSchema<Set<T>>, _ value: Set<T>) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.map(\.firestoreValue)
  }
  
  /// Creates a field value for an optional set field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<Set<T>>, _ value: [T]) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.map(\.firestoreValue)
  }
  
  /// Creates a field value for an optional set field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<Set<T>>, _ value: [T]?) {
    self.path = DocumentDataField<Model>(field).path
    self.value = if let value {
      value.map(\.firestoreValue)
    } else {
      NSNull()
    }
  }
  
  /// Creates a field value for a map field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreSchema<[String: T]>, _ value: [String: T]) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.mapValues(\.firestoreValue)
  }
  
  /// Creates a field value for an optional map field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<[String: T]>, _ value: [String: T]) {
    self.path = DocumentDataField<Model>(field).path
    self.value = value.mapValues(\.firestoreValue)
  }
  
  /// Creates a field value for an optional map field.
  public init<T: FirestoreModel>(_ field: (Model.Schema) -> FirestoreOptionalSchema<[String: T]>, _ value: [String: T]?) {
    self.path = DocumentDataField<Model>(field).path
    self.value = if let value {
      value.mapValues(\.firestoreValue)
    } else {
      NSNull()
    }
  }
}

extension DocumentData {
  /// Creates a typed field update backed by a server-side Firestore transform.
  private init(
    _ field: DocumentDataField<Model>,
    _ transform: some FirestoreTransform
  ) {
    self.path = field.path
    self.value = transform.firestoreValue
  }
  
  /// Creates a transformed update for a non-optional field.
  public init<T>(
    _ field: (Model.Schema) -> FirestoreSchema<T>,
    _ transform: some FirestoreTransform<T>
  ) {
    self.init(DocumentDataField<Model>(field), transform)
  }
  
  /// Creates a transformed update for an optional field.
  public init<T>(
    _ field: (Model.Schema) -> FirestoreOptionalSchema<T>,
    _ transform: some FirestoreTransform<T?>
  ) {
    self.init(DocumentDataField<Model>(field), transform)
  }
}

/// A typed reference to a model field path.
///
/// You can create a field using closure expression or keypath expression.
/// ```swift
/// let name = DocumentDataField<User> { $0.profile.displayName }
/// // name.path == "profile.displayName"
/// let age = DocumentDataField<User>(\.profile.age)
/// // age.path == "profile.age"
/// ```
public struct DocumentDataField<Model: FirestoreModel> {
  /// The dot-separated Firestore field path.
  public let path: String
  
  /// Creates a field path for a scalar or single Firestore value.
  public init<T>(_ field: (Model.Schema) -> FirestoreSchema<T>) {
    self.path = field(Model.schema(path: []))._firestorePath.joined(separator: ".")
  }

  /// Creates a field path for an optional scalar or model field.
  public init<T>(_ field: (Model.Schema) -> FirestoreOptionalSchema<T>) {
    self.path = field(Model.schema(path: []))._firestorePath.joined(separator: ".")
  }
}
