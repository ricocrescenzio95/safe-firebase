# ``SafeFirestore``

Strongly typed access to Cloud Firestore for Swift models, schemas, predicates, and queries.

SafeFirestore adds a type-safe layer on top of the Firebase Firestore SDK. Define your
models once, generate their Firestore schema with a macro, and use that schema to
build queries and partial updates without manually spelling field paths.

The library is designed around:

- **Generated schemas** — Model properties become typed schema values that can be
  traversed through nested models and coding keys.
- **Typed predicates** — Comparisons and collection operators are available only
  for compatible field types.
- **Composable queries** — Build filters with ``TypedQueryProtocol/where(_:)``,
  then add ordering, limits, and pagination.
- **Typed documents and snapshots** — Keep the model type attached to collection
  references, document references, and query results.
- **Partial updates** — Update selected fields through ``DocumentData`` and
  typed schema expressions.

## Quick Start

### Define a model

Use ``FirestoreCollection(_:)`` for a model stored in a named top-level
collection. The macro also generates the ``FirestoreModel`` conformance and
the model's schema.

```swift
import FirebaseFirestore
import SafeFirestore

@FirestoreCollection("users")
struct User: Codable, Sendable {
    let id: String
    var displayName: String
    var age: Int
    var isActive: Bool
}
```

### Create a typed collection reference

```swift
let users = Firestore.firestore()
    .collection(User.self)

let user = users.document("ada")
```

The model type is preserved by the reference, so reads, writes, and queries all
remain associated with `User`.

### Write and read a document

```swift
let ada = User(
    id: "ada",
    displayName: "Ada",
    age: 36,
    isActive: true
)

try await user.setData(ada)

let snapshot = try await user.getDocument()
let decoded: User = try snapshot.data()
```

### Build a typed query

Pass a closure to ``TypedQueryProtocol/where(_:)``. Its parameter is
`User/Schema`, so every field path is checked by the compiler.

```swift
let adults = users
    .where { $0.isActive == true && $0.age >= 18 }
    .order(by: \.displayName)
    .limit(to: 20)

let result = try await adults.getDocuments()

for document in result.documents {
    let user: User = try document.data()
    print(user.displayName)
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``FirestoreModel``
- ``FirestoreCollection``
- ``FirestoreModel()``
- ``FirestoreCollection(_:)``
- ``FirestoreExclude()``
- ``SchemaOf``

### Collections and Documents

- ``TypedCollectionReference``
- ``FirebaseFirestoreInternal/Firestore/collection(_:)``
- ``TypedCollectionReference/document()``
- ``TypedCollectionReference/document(_:)``
- ``TypedDocumentReference``
- <doc:DocumentsAndUpdates>

### Server-Side Transforms

- <doc:Transforms>
- ``FirestoreTransform``
- ``FirestoreServerTimestamp``
- ``FirestoreIncrement``
- ``FirestoreMaximum``
- ``FirestoreMinimum``
- ``FirestoreArrayUnion``
- ``FirestoreArrayRemove``
- ``FirestoreDelete``

### Batched Writes and Transactions

- <doc:BatchedWritesAndTransactions>
- ``TypedWriteBatch``
- ``TypedTransaction``
- ``TypedTransactionError``
- ``FirebaseFirestoreInternal/Firestore/typedBatch()``
- ``FirebaseFirestoreInternal/Firestore/runTypedTransaction(with:_:)``

### Models and Schemas

- <doc:ModelsAndSchemas>
- ``FirestoreSchema``
- ``FirestoreOptionalSchema``
- <doc:AnyFirestoreValue>
- ``AnyFirestoreValue``

### Predicates and Operators

- <doc:PredicatesAndOperators>
- ``FirestorePredicateExpression``
- ``FirestorePredicate``
- ``TypedQueryProtocol/where(_:)``

### Queries

- <doc:Queries>
- <doc:Aggregations>
- ``TypedAggregateQuery``
- ``TypedAggregateQuerySnapshot``
- ``TypedAggregateField``
- ``TypedAggregateField/sum(_:)-((Model.Schema)->FirestoreSchema<T>)``
- ``TypedAggregateField/average(_:)-((Model.Schema)->FirestoreSchema<T>)``
- ``TypedAggregateQuerySnapshot/get(_:)->Int?``
- ``TypedQueryProtocol``
- ``TypedQuery``
- ``TypedQueryProtocol/order(by:descending:)-((Model.Schema)->FirestoreSchema<T>,_)``
- ``TypedQueryProtocol/limit(to:)``
- ``TypedQueryProtocol/start(after:)``
- ``TypedQueryProtocol/getDocuments()``

### Snapshots and Live Updates

- <doc:Snapshots>
- ``TypedDocumentSnapshot``
- ``TypedQuerySnapshot``
- ``TypedQueryProtocol/snapshots``
