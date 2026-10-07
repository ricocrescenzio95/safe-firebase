<p align="center">
<img src="./Sources/SafeFirestore/SafeFirestore.docc/Resources/app-icon@3x.png" width="200">
</p>

# safe-firebase

### Strongly typed access to Cloud Firestore for Swift models, schemas, predicates, and queries.

<p>
  <a href="https://github.com/ricocrescenzio95/safe-firebase/actions/workflows/tests.yml"><img src="https://github.com/ricocrescenzio95/safe-firebase/actions/workflows/tests.yml/badge.svg?branch=main"></a>
  <a href="https://github.com/ricocrescenzio95/safe-firebase/releases"><img src="https://img.shields.io/github/v/release/ricocrescenzio95/safe-firebase?include_prereleases&label=Swift%20Package%20Manager"></a>
  <a href="https://swiftpackageindex.com/ricocrescenzio95/safe-firebase"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fricocrescenzio95%2Fsafe-firebase%2Fbadge%3Ftype%3Dswift-versions"></a>
  <a href="https://swiftpackageindex.com/ricocrescenzio95/safe-firebase"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fricocrescenzio95%2Fsafe-firebase%2Fbadge%3Ftype%3Dplatforms"></a>
  <a href="https://saythanks.io/to/rico.crescenzio"><img src="https://img.shields.io/badge/SayThanks.io-%E2%98%BC-1EAEDB.svg"></a>
  <a href="https://www.paypal.com/donate/?hosted_button_id=RWDBC8TS5CNVA"><img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat"></a>
</p>

## Why safe-firebase?

Firebase Firestore is flexible, but string-based collection names, field paths, and query operators can move errors from compile time to runtime.

safe-firebase adds a type-safe Swift layer on top of Firebase Firestore:

- **Generated schemas** — `@FirestoreModel` generates a schema and provides `Codable` and `Sendable` for the model.
- **Typed collections** — `@FirestoreCollection` associates a model with a top-level collection.
- **Typed queries** — access fields through key paths and use only operators supported by their types.
- **Typed documents** — read snapshots and create updates without repeating string field paths.
- **Native Firebase integration** — keep using FirebaseFirestore references, snapshots, batches, and transactions.

## Features

- **`@FirestoreModel`** — generate a `FirestoreModel` conformance and schema
- **`@FirestoreCollection`** — generate a model conformance with a collection name
- **`@FirestoreExclude`** — exclude stored properties from the generated schema
- **Typed collection and document references** — preserve the model type across reads and writes
- **Typed predicates** — support comparisons, membership, null checks, arrays, sets, dictionaries, and logical combinations
- **Async/await APIs** — use Swift concurrency for Firestore operations
- **Aggregations, batched writes, and transactions** — keep advanced Firestore operations typed
- **Swift Package Manager** — supports iOS 15+, macOS 12+, macCatalyst 15+, tvOS 15+, and watchOS 9+

## Installation

`safe-firebase` can be installed using Swift Package Manager.

1. In Xcode open **File/Swift Packages/Add Package Dependency...** menu.
2. Copy and paste the package URL:

```
https://github.com/ricocrescenzio95/safe-firebase
```

3. Add the `SafeFirestore` product to your target.
4. Configure Firebase as usual in your application before using Firestore.

For more details refer to [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) documentation.

## Usage

### Define a Firestore Model

Annotate a model with `@FirestoreModel`. The macro already provides `Codable` and `Sendable`; custom `CodingKeys` are supported and determine the Firestore field names. Use `@FirestoreCollection` when the model belongs to a named top-level collection:

```swift
import SafeFirestore

@FirestoreCollection("users")
struct User {
    let id: String
    var displayName: String
    var age: Int
    var isActive: Bool
    var nickname: String?
}
```

### Use a Typed Collection

Create a collection reference from Firestore. The model type is carried through reads, writes, and queries:

```swift
import FirebaseFirestore
import SafeFirestore

let users = Firestore.firestore()
    .collection(User.self)
```

### Write and Read a Document

Use the typed document reference with Swift's async/await APIs:

```swift
let reference = users.document("ada")

try await reference.setData(from: User(
    id: "ada",
    displayName: "Ada",
    age: 36,
    isActive: true,
    nickname: nil
))

let snapshot = try await reference.getDocument()
let user: User = try snapshot.data()
```

### Query Typed Fields

The query closure exposes generated schema fields. Invalid operators and incompatible values fail at compile time:

```swift
let adults = users
    .where { $0.age >= 18 && $0.isActive == true }

let withNickname = users
    .where { $0.nickname.isNotNull }

let selectedAges = users
    .where { $0.age.isIn([18, 21, 36]) }
```

### Update Typed Fields

Use a typed field path when updating a document:

```swift
let update = DocumentData<User>(\.displayName, "Ada")

try await reference.updateData([update])
```

### Exclude a Property

Computed properties are excluded by default. Use `@FirestoreExclude` for stored properties that belong to the Swift model but should not be part of the Firestore schema:

```swift
@FirestoreModel
struct Session {
    let token: String

    var isExpired: Bool {
        token.isEmpty
    }

    @FirestoreExclude
    var localName: String?
}
```

For advanced usage, refer to the full DocC documentation.

## Limitations

- **Models must be `Codable`.** The generated schema and Firestore value conversion use the model's Codable representation.
- **Firebase must still be configured by the host app.** safe-firebase provides the typed Firestore layer; it does not replace Firebase app configuration or security rules.

## Documentation

Use Apple `DocC` generated documentation, from Xcode, **Product > Build Documentation**.

## Found a bug or want new feature?

If you found a bug, you can open an issue as a bug [here](https://github.com/ricocrescenzio95/safe-firebase/issues/new?assignees=ricocrescenzio95&labels=bug&template=bug_report.md&title=%5BBUG%5D)
