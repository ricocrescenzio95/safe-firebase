# Queries

A typed query starts from a TypedCollectionReference and uses where to receive a predicate built from the model schema.

## where

where receives a closure whose parameter is Model.Schema. The closure does not use string paths: every member access is checked by the compiler.

```swift
let adults = Firestore.firestore()
    .collection(User.self)
    .where { $0.age >= 18 }
```

The resulting query can be configured through a chain:

```swift
let query = Firestore.firestore()
    .collection(User.self)
    .where { $0.isActive == true && $0.age >= 18 }
    .order(by: { $0.age })
    .limit(to: 50)
```

## Reusable predicates

Predicates can be extracted into functions when the same rule is used in several queries:

```swift
func adultPredicate(_ schema: User.Schema) -> some FirestorePredicateExpression {
    schema.age >= 18
}

let adults = Firestore.firestore()
    .collection(User.self)
    .where(adultPredicate)
```

## Ordering

order(by:) uses the same typed schema approach:

```swift
let ordered = Firestore.firestore()
    .collection(User.self)
    .order(by: { $0.displayName })
```

## Limits and pagination

Use limits and cursor values to fetch a page of results:

```swift
let lastDisplayName = "Ada"
let page = Firestore.firestore()
    .collection(User.self)
    .where { $0.isActive == true }
    .order(by: { $0.displayName })
    .limit(to: 20)
    .start(after: [lastDisplayName])
```

The query also provides start(at:), start(after:), end(at:), and end(before:), including variants that receive a TypedDocumentSnapshot.

For server-side count, sum, and average operations, see <doc:Aggregations>.

## Executing a query

getDocuments() returns a TypedQuerySnapshot when the model is Decodable:

```swift
let result = try await page.getDocuments()

for document in result.documents {
    let user: User = try document.data()
    print(user.displayName)
}
```

Use snapshots to listen for live changes:

```swift
for try await result in page.snapshots {
    print("Documents: \(result.count)")
}
```
