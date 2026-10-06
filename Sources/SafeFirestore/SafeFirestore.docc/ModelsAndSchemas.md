# Models and Schemas

`@FirestoreModel` generates the schema types used by typed queries and updates. The generated schema mirrors the model's nesting and preserves the access level of each original property.

For a model such as:

```swift
@FirestoreModel
struct User: Codable {
    var displayName: String
    var age: Int
    var nickname: String?
}
```

the generated API exposes typed fields through the schema value passed to a query closure or through typed field paths:

```swift
let users = Firestore.firestore()
    .collection(User.self)

let adults = users.where { $0.age >= 18 }
let nicknameField = DocumentDataField<User>(\.nickname)
```

A non-optional field is represented by FirestoreSchema. An optional field is represented by FirestoreOptionalSchema. This distinction controls which operators are available. Schema values are normally obtained as the closure parameter in `where`; use `DocumentDataField<Model>(\\.property)` when an API requires a reusable field path.

## Nested models

Nested models are accessed through dynamic member lookup:

```swift
@FirestoreModel
struct Address: Codable {
    var city: String
    var country: String
}

@FirestoreModel
struct Customer: Codable {
    var name: String
    var address: Address
}

let customers = Firestore.firestore()
    .collection(Customer.self)

let customersInRome = customers.where { $0.address.city == "Rome" }
```

## Optional fields

Optional schemas support null checks in addition to operators valid for the wrapped value:

```swift
let users = Firestore.firestore()
    .collection(User.self)

let hasNickname = users.where { $0.nickname.isNotNull }
let hasNoNickname = users.where { $0.nickname.isNull }
let nicknameIsAda = users.where { $0.nickname == "Ada" }
```

## Collections and dictionaries

Array, Set, and Dictionary properties retain their collection-specific capabilities:

```swift
@FirestoreModel
struct Profile: Codable {
    var tags: [String]
    var roles: Set<String>
    var metadata: [String: String]
}

let profiles = Firestore.firestore()
    .collection(Profile.self)

let taggedProfiles = profiles.where { $0.tags.arrayContains("swift") }
let adminProfiles = profiles.where { $0.roles.arrayContains("admin") }
let productionProfiles = profiles.where {
    $0.metadata["environment"] == "production"
}
```

The available operators depend on the value represented by each schema. This prevents applying scalar comparisons to a collection field or collection membership operators to an incompatible value.
