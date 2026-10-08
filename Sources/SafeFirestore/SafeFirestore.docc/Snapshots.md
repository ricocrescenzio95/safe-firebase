# Snapshots

Typed snapshots keep Firestore data associated with the model used to read it.

## Document snapshots

A TypedDocumentSnapshot can decode the complete model:

```swift
let snapshot = try await reference.getDocument()
let user: User = try snapshot.data()
```

It can also read individual fields through typed function key paths:

```swift
let nameField = DocumentDataField<User>(\.displayName)
let ageField = DocumentDataField<User>(\.age)

let name: String? = snapshot.get(nameField)
let age: Int? = snapshot.get(ageField)
```

Field reads are useful when a query or listener only needs a small part of a document.

## Query snapshots

A query returns a TypedQuerySnapshot containing typed document snapshots:

```swift
let result = try await query.getDocuments()

for document in result.documents {
    let user: User = try document.data()
    print(user.displayName)
}
```

The snapshot also exposes document changes, so listeners can distinguish added, modified, and removed documents:

```swift
for change in result.documentChanges {
    print(change.type)
}
```

Use the typed query APIs together with async/await or snapshots() to keep both one-shot reads and live updates aligned with the model schema.

## Snapshot sequences

Document references and typed queries expose two live snapshot sequence variants:

- `snapshots()` is throwing. It yields typed snapshots through an `AsyncThrowingStream`. When Firestore reports an error, the error is thrown from `next()` and the stream finishes; the listener is removed when the stream terminates.
- `nonThrowingSnapshots()` yields `Result` values through an `AsyncStream`. A Firestore error is emitted as `.failure(error)`, so the error is intercepted as an element and does not finish the stream. The same iterator can receive later snapshot events until it is cancelled.

Choose the throwing variant when an error should end the consuming task. Choose the non-throwing variant when the listener should remain alive and the consumer should decide how to handle each error:

```swift
var snapshots = query.nonThrowingSnapshots.makeAsyncIterator()

while let result = await snapshots.next() {
    switch result {
    case .success(let snapshot):
        print(snapshot.count)
    case .failure(let error):
        print("Listener error: \\(error)")
    }
}
```
