# Getting Started

Define a Codable model and annotate it with @FirestoreModel. If the model belongs to a named collection, add @FirestoreCollection.

```swift
@FirestoreCollection("users")
struct User: Codable {
    let id: String
    var displayName: String
    var age: Int
    var isActive: Bool
    var personalData: PersonalData?
}
  
@FirestoreModel
struct PersonalData: Codable {
    var firstName: String
    var lastName: String
}
```

Create a typed collection reference from Firestore:

```swift
let users = Firestore.firestore()
    .collection(User.self)
```

The resulting reference carries User's type through reads, writes, and queries.

## Writing and reading a document

```swift
let reference = users.document("ada")

try await reference.setData(User(
    id: "ada",
    displayName: "Ada",
    age: 36,
    isActive: true
))

let snapshot = try await reference.getDocument()
let user: User = try snapshot.data()
```

## Typed field access

Generated schema fields can be used in query closures. For document updates and typed snapshot reads, use a ``DocumentData``:

```swift
let update = DocumentData<User>(\.displayName, "Ada")

try await reference.updateData(update)

let snapshot = try await reference.getDocument()
let name: String? = snapshot.get(nameField)
```

## Excluding a property

Use @FirestoreExclude for values that belong to the Swift model but must not be in Firestore schema.
Computed properties are excluded by default:

```swift
@FirestoreModel
struct Session: Codable {
    let token: String

    // computed property excluded by default
    var isExpired: Bool {
        token.isEmpty
    }
    
    // will not be included in the generated Schema 
    @FirestoreExclude
    var name: String?
}
```
