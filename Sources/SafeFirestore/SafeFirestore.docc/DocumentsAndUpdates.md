# Documents and Updates

`TypedDocumentReference` keeps the model type attached to a document path. It
supports full writes, reads, deletes, partial updates, and server-side
transforms.

## Full writes

``TypedDocumentReference/setData(from:encoder:)`` encodes and replaces the
document:

```swift
let reference = Firestore.firestore()
    .collection(User.self)
    .document("ada")

let user = User(
    id: "ada",
    displayName: "Ada",
    age: 36,
    isActive: true
)

try await reference.setData(from: user)
```

## Partial updates

Use `DocumentData` to update only selected fields:

```swift
let update = DocumentData<User>(\.displayName, "Ada")

try await reference.updateData([update])
```

The field path and value are checked against the model schema.

## Firestore transforms

Transforms are server-side operations. They are not ordinary values: Firestore
evaluates them atomically while applying the write.

### Server timestamps

`FirestoreServerTimestamp` stores the timestamp assigned by the Firestore
server. The target model field should normally be a `Date` or `Date?`.

```swift
let update = DocumentData<User>(\.updatedAt, FirestoreServerTimestamp())

try await reference.updateData([update])
```

### Numeric transforms

`FirestoreIncrement` adds to the current value.
`FirestoreMaximum` keeps the greater value, and `FirestoreMinimum` keeps the
smaller value.

```swift
let updates: [DocumentData<User>] = [
    .init(\.loginCount, FirestoreIncrement(1)),
    .init(\.highScore, FirestoreMaximum(100)),
    .init(\.lowScore, FirestoreMinimum(0))
]

try await reference.updateData(updates)
```

### Array and set transforms

`FirestoreArrayUnion` adds elements without duplicating existing values.
`FirestoreArrayRemove` removes matching elements. Both can target array and
set fields.

```swift
let updates: [DocumentData<User>] = [
    .init(\.tags, FirestoreArrayUnion(["swift"])),
    .init(\.tags, FirestoreArrayRemove(["legacy"]))
]

try await reference.updateData(updates)
```

### Deleting an optional field

`FirestoreDelete` removes the field entirely from the document:

```swift
let update = DocumentData<User>(\.nickname, FirestoreDelete())

try await reference.updateData([update])
```

## Merging selected fields

When writing a complete model, pass typed field paths through `mergeFields`:

```swift
try await reference.setData(
    from: user,
    mergeFields: [
        DocumentDataField(\.displayName),
        DocumentDataField(\.isActive)
    ]
)
```
