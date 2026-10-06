# Predicates and Operators

A Firestore predicate is a typed expression built from a model schema. The expression is translated into a Firestore filter when it is passed to where.

## Scalar comparisons

Comparable scalar fields support equality, inequality, and ordering. The schema is accessed through the parameter supplied to `where`:

```swift
let adults = Firestore.firestore()
    .collection(User.self)
    .where { $0.age >= 18 }

let minors = Firestore.firestore()
    .collection(User.self)
    .where { $0.age < 18 }

let namedAda = Firestore.firestore()
    .collection(User.self)
    .where { $0.displayName == "Ada" }
```

The supported comparison operators are:

- == and != for equality;
- <, <=, >, and >= for comparable values;
- isIn and isNotIn for membership in a list of values.

```swift
let selectedAges = Firestore.firestore()
    .collection(User.self)
    .where { $0.age.isIn([18, 21, 36]) }

let excludedAges = Firestore.firestore()
    .collection(User.self)
    .where { $0.age.isNotIn([0, 17]) }
```

## Boolean fields

Boolean schemas can be compared with true and false or negated directly:

```swift
let active = Firestore.firestore()
    .collection(User.self)
    .where { $0.isActive == true }

let inactive = Firestore.firestore()
    .collection(User.self)
    .where { !$0.isActive }
```

## Optional fields

Optional schemas keep the wrapped value's operators and also expose null checks. The checks are predicates and can be passed directly to a typed `where` clause:

```swift
let query = firestore
    .collection(User.self)
    .where { $0.nickname.isNotNull }

let missingNicknames = firestore
    .collection(User.self)
    .where { $0.nickname.isNull }
```

`isNull` matches fields that are absent or explicitly stored as null. `isNotNull` matches fields whose value is present and not null. They are available for optional scalar fields, optional nested models, and optional collections.

The wrapped value's operators remain available as well:

```swift
let namedAda = firestore
    .collection(User.self)
    .where { $0.nickname == "Ada" }

let adultsWithNickname = firestore
    .collection(User.self)
    .where { $0.age >= 18 && $0.nickname.isNotNull }
```

## Arrays

Array schemas support equality and array membership operations:

```swift
let hasSwift = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.tags.arrayContains("Swift") }

let hasAnyLanguage = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.tags.arrayContainsAny(["Swift", "Kotlin"]) }

let exactTags = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.tags == ["Swift", "Firestore"] }
```

## Sets

Set schemas expose operations that preserve set membership semantics:

```swift
let hasAdminRole = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.roles.arrayContains("admin") }

let hasAnyPrivilegedRole = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.roles.arrayContainsAny(["admin", "owner"]) }
```

## Dictionaries

Dictionary schemas support equality and typed access to a value at a key:

```swift
let production = Firestore.firestore()
    .collection(Profile.self)
    .where { $0.metadata["environment"] == "production" }

let exactMetadata = Firestore.firestore()
    .collection(Profile.self)
    .where {
        $0.metadata == ["environment": "production"]
    }
```

## Combining predicates

Use && and || to combine compatible predicate expressions. Use parentheses when grouping improves readability:

```swift
let visibleAdults = Firestore.firestore()
    .collection(User.self)
    .where {
        ($0.isActive == true)
            && ($0.age >= 18)
    }

let eligible = Firestore.firestore()
    .collection(User.self)
    .where {
        ($0.age >= 18)
            || ($0.isActive == true)
    }
```

## Compile-time restrictions

Operators are intentionally available only for compatible schema types. For example, a String field cannot use numeric ordering, and a Dictionary field cannot use scalar comparison. These invalid combinations fail during compilation instead of producing a runtime query error.
