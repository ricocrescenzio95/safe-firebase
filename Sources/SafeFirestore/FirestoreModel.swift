import Foundation
import FirebaseFirestore

/// A type that can expose a type-safe Firestore schema.
///
/// Apply ``FirestoreModel()`` to a model to generate its schema. ``FirestoreModel``
/// already inherits `Codable` and `Sendable`, so neither conformance needs to be
/// written explicitly. Custom `CodingKeys` are supported and continue to define
/// the Firestore field names.
///
/// ```swift
/// @FirestoreModel
/// struct User {
///     var name: String
///     var age: Int
/// }
/// ```
public protocol FirestoreModel<Schema>: Sendable, Codable {
  /// The schema type generated for the model.
  associatedtype Schema: FirestoreSchemaProtocol
  
  /// The value passed to the Firebase Firestore SDK.
  var firestoreValue: Any { get }
}

/// A ``FirestoreModel`` that is stored in a named top-level Firestore collection.
///
/// ```swift
/// @FirestoreCollection("users")
/// struct User {
///     var name: String
///     var age: Int
/// }
///
/// let adults = Firestore.firestore()
///     .collection(User.self)
///     .where { $0.age >= 18 }
/// ```
public protocol FirestoreCollection: FirestoreModel {
  /// The name of the Firestore collection containing the model.
  static var collectionName: String { get }
}

/// The generated schema type associated with a ``FirestoreModel``.
public typealias SchemaOf<T: FirestoreModel> = T.Schema

// MARK: - Macro

@attached(
  extension,
  conformances: FirestoreModel,
  names: named(Schema), named(firestoreValue)
)
/// Generates the Firestore schema and ``FirestoreModel`` conformance for a model.
public macro FirestoreModel() =
#externalMacro(module: "SafeFirebaseMacros", type: "FirestoreModelMacro")

@attached(
  extension,
  conformances: FirestoreCollection, FirestoreModel,
  names: named(collectionName), named(Schema), named(firestoreValue)
)
/// Generates a Firestore schema and associates the model with a collection name.
///
/// - Parameter collectionName: The name of the Firestore collection.
///
/// Use ``FirestoreCollection`` when the model is stored in a top-level
/// collection and should be usable with `Firestore.collection(_:)`.
public macro FirestoreCollection(_ collectionName: StaticString) =
#externalMacro(module: "SafeFirebaseMacros", type: "FirestoreModelMacro")

@attached(peer)
/// Excludes a stored property from the generated Firestore schema.
public macro FirestoreExclude() =
#externalMacro(module: "SafeFirebaseMacros", type: "FirestoreExcludeMacro")
