# Aggregation Queries

SafeFirestore provides typed wrappers for Firestore aggregation queries. Aggregations
are built from the same model schema used by predicates and document updates.

## Define aggregations

Use the model's key paths when creating aggregate fields:

```swift
let query = Firestore.firestore()
    .collection(User.self)
    .aggregate([
        .count(),
        .sum(\.age),
        .average(\.age)
    ])
```

The type-preserving form of `TypedAggregateField/sum(_:)` uses the value type of
the selected property. A sum over an `Int` field is represented by
`TypedAggregateField` with an `Int` result, while a sum over a `Double` field
has a `Double` result.

Optional numeric properties are supported as well. The optionality of the field
does not make the aggregation result optional at the type level; a missing or
empty aggregation is represented by the result returned from Firestore.

```swift
@FirestoreCollection("users")
struct User {
    var age: Int
    var optionalScore: Double?
}

let query = Firestore.firestore()
    .collection(User.self)
    .aggregate([
        .sum(\.age),
        .sum(\.optionalScore)
    ])
```

`average` always returns a `Double`, regardless of whether the source field is
an integer or floating-point property.

## Execute and read results

Call `TypedAggregateQuery/getAggregation(source:)` to execute the request.
Pass the same typed aggregate expression to `TypedAggregateQuerySnapshot/get(_:)`
to decode its result.

```swift
let result = try await query.getAggregation()

let count: Int? = result.get(.count())
let totalAge: Int? = result.get(.sum(\.age))
let averageAge: Double? = result.get(.average(\.age))
```

The explicit result types are usually inferred automatically from the aggregate
field. They can also be written explicitly when documenting or disambiguating a
complex expression:

```swift
let totalAge: TypedAggregateField<User, Int> = .sum(\.age)
let averageAge: TypedAggregateField<User, Double> = .average(\.age)

let result = try await Firestore.firestore()
    .collection(User.self)
    .aggregate([totalAge, averageAge])
    .getAggregation()

let total = result.get(totalAge)
let average = result.get(averageAge)
```

## Query aggregations

Aggregations can be applied after filtering, ordering, and limiting a typed query.
The aggregation reads the result set produced by the query.

```swift
let activeUsers = Firestore.firestore()
    .collection(User.self)
    .where { $0.isActive == true && $0.age >= 18 }
    .limit(to: 100)
    .aggregate([
        .count(),
        .average(\.age)
    ])

let result = try await activeUsers.getAggregation()
let count: Int? = result.get(.count())
let averageAge: Double? = result.get(.average(\.age))
```

Firestore returns numeric aggregate values boxed as `NSNumber` by the Firebase
SDK. SafeFirestore decodes that value into the result type carried by the typed
aggregate field. In particular, `average` is always decoded as `Double`.
