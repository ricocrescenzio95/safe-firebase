# Firestore Transforms

Firestore transforms are server-side write operations. They are evaluated by
Firestore while a document is being written, so the client does not need to
read the current value first.

Create a transform and pass it to `DocumentData`:

```swift
let update = DocumentData<User>(
    { $0.loginCount },
    FirestoreIncrement<Int>(1)
)

try await reference.updateData([update])
```

## Timestamp

`FirestoreServerTimestamp` asks Firestore to assign the server timestamp.
Use `Date` or `Date?` as the target field type.

```swift
let update = DocumentData<User>(
    { $0.updatedAt },
    FirestoreServerTimestamp<Date?>()
)
```

## Numeric transforms

`FirestoreIncrement` adds a value atomically.
`FirestoreMaximum` writes the value only when it is greater than the current
value. `FirestoreMinimum` does the same for smaller values.

```swift
let updates: [DocumentData<User>] = [
    .init({ $0.count }, FirestoreIncrement<Int>(1)),
    .init({ $0.maximumScore }, FirestoreMaximum<Int>(100)),
    .init({ $0.minimumScore }, FirestoreMinimum<Int>(0))
]
```

The numeric type is part of the transform's generic parameter, so a transform
for `Int` cannot be applied to a `String` field.

## Array and set transforms

`FirestoreArrayUnion` adds values without duplicating existing elements.
`FirestoreArrayRemove` removes matching values. They support both array and
set fields.

```swift
let updates: [DocumentData<User>] = [
    .init(
        { $0.tags },
        FirestoreArrayUnion<Set<String>>(["swift"])
    ),
    .init(
        { $0.tags },
        FirestoreArrayRemove<Set<String>>(["legacy"])
    )
]
```

## Delete

`FirestoreDelete` removes an optional field from the document:

```swift
let update = DocumentData<User>(
    { $0.nickname },
    FirestoreDelete<String?>()
)
```

A deleted field is different from a field whose value is `nil`: the field is
removed from the stored document entirely.
