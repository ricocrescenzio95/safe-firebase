# Batched Writes and Transactions

Use ``FirebaseFirestoreInternal/Firestore/typedBatch()`` and
``FirebaseFirestoreInternal/Firestore/runTypedTransaction(with:_:)`` when several typed writes must be
coordinated.

Both APIs keep the model associated with each
``TypedDocumentReference``. Field-level writes use ``DocumentData`` so nested
paths and server-side transforms remain type checked.

```swift
import SafeFirestore

let batch = firestore.typedBatch()

try batch.setData(
    from: user,
    forDocument: userReference
)

batch.updateData(
    [
        DocumentData(\.displayName, "Ada Lovelace"),
        DocumentData(\.loginCount, FirestoreIncrement(1))
    ],
    forDocument: userReference
)

batch.deleteDocument(archivedUserReference)

try await batch.commit()
```

The encoded-model overloads are useful when writing a complete value. Use
``TypedWriteBatch/setData(_:forDocument:)`` and its merge variants for partial
updates and transforms:

```swift
let updates: [DocumentData<User>] = [
    DocumentData(\.profile.lastSeen, FirestoreServerTimestamp()),
    DocumentData(\.tags, FirestoreArrayUnion(["swift"]))
]

let batch = firestore.typedBatch()
batch.setData(updates, forDocument: userReference, merge: true)
try await batch.commit()
```

The asynchronous throwing commit is recommended because it reports failures.
The callback-style commit is available when integrating with existing
callback-based code, but it does not expose a completion error.

## Transactions

A transaction reads the current state and conditionally writes a new state.
The closure can throw, so typed snapshot decoding errors and validation
failures can be returned to the caller:

```swift
let newCount: Int = try await firestore.runTypedTransaction { transaction in
    let snapshot = try transaction.getDocument(counterReference)
    let counter: Counter = try snapshot.data()

    let nextCount = counter.value + 1
    transaction.updateData(
        [DocumentData({ $0.value }, nextCount)],
        forDocument: counterReference
    )

    return nextCount
}
```

Pass `TransactionOptions` when the transaction needs custom Firebase
options:

```swift
let result: Counter = try await firestore.runTypedTransaction(
    with: TransactionOptions()
) { transaction in
    let snapshot = try transaction.getDocument(counterReference)
    let counter: Counter = try snapshot.data()

    transaction.setData(
        from: counter,
        forDocument: counterReference,
        merge: true
    )

    return counter
}
```

A transaction can contain at most 500 writes. Each server-side transform
used in a transaction counts as an additional write. Firebase retries the
closure when data read by the transaction changes before the commit; by
default, Firebase makes up to five attempts, or uses the limit configured in
`TransactionOptions`.

Because the closure can run multiple times, do not perform irreversible side
effects, such as sending notifications or mutating unrelated application state,
inside it. All reads must happen before writes, and transaction reads do not
include local changes that have not been committed.

Transactions require an online client. If reads or the final commit cannot
reach Firestore, the transaction fails and the async method throws. The value
returned by the closure is returned to the caller only after the transaction
has been successfully committed.

## Choosing between batches and transactions

Use a batch when the values to write are already known and no read is needed.
Use a transaction when a write depends on the current value stored in
Firestore.

Both APIs use the same typed field update and transform types:

```swift
let patch: [DocumentData<User>] = [
    DocumentData(\.loginCount, FirestoreIncrement(1)),
    DocumentData(\.tags, FirestoreArrayRemove(["legacy"]))
]

let batch = firestore.typedBatch()
batch.updateData(patch, forDocument: userReference)
try await batch.commit()
```
