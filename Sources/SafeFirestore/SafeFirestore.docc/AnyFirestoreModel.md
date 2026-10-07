# ``AnyFirestoreModel``

Use ``AnyFirestoreModel`` to represent a Firestore value when its concrete
Swift type is not known ahead of time.

It is useful for inspecting arbitrary document data, handling dynamic fields,
or constructing values for generic update code. Each enum case identifies the
underlying Firestore kind.

## Supported values

``AnyFirestoreModel`` supports:

- null
- Boolean and signed 64-bit integer values
- double-precision floating-point values
- strings
- timestamps and dates
- geographic points
- document references
- binary data
- arrays of ``AnyFirestoreModel``
- maps from field names to ``AnyFirestoreModel``

## Create values

Create a value by selecting the matching case:

```swift
let value: AnyFirestoreModel = .map([
    "name": .string("Ada"),
    "age": .int(36),
    "isActive": .bool(true),
    "tags": .array([.string("swift"), .string("firestore")])
])
```

Use the typed accessors to inspect a value without switching over every case:

```swift
if let name = value.map?["name"]?.string {
    print(name)
}
```

An accessor returns the underlying value for its matching case and nil
otherwise. ``AnyFirestoreModel/isNull`` is the equivalent check for
.null.

## Convert to a Firestore value

Use ``AnyFirestoreModel/firestoreValue`` when passing a value to an API that
expects the Firebase SDK representation:

```swift
let firestoreData: [String: Any] = [
    "profile": value.firestoreValue
]
```

Arrays and maps are converted recursively.

## Codable

The type conforms to Codable. Encoding preserves the selected case, and
decoding accepts the supported Firestore value kinds. If the input cannot be
represented as a Firestore value, decoding throws a data-corrupted error.

## Topics

### Value representation

- ``AnyFirestoreModel/null``
- ``AnyFirestoreModel/bool(_:)``
- ``AnyFirestoreModel/int(_:)``
- ``AnyFirestoreModel/double(_:)``
- ``AnyFirestoreModel/string(_:)``
- ``AnyFirestoreModel/timestamp(_:)``
- ``AnyFirestoreModel/date(_:)``
- ``AnyFirestoreModel/geoPoint(_:)``
- ``AnyFirestoreModel/documentReference(_:)``
- ``AnyFirestoreModel/data(_:)``
- ``AnyFirestoreModel/array(_:)``
- ``AnyFirestoreModel/map(_:)``

### Inspection and conversion

- ``AnyFirestoreModel/firestoreValue``
- ``AnyFirestoreModel/isNull``
- ``AnyFirestoreModel/bool``
- ``AnyFirestoreModel/int``
- ``AnyFirestoreModel/double``
- ``AnyFirestoreModel/string``
- ``AnyFirestoreModel/timestamp``
- ``AnyFirestoreModel/date``
- ``AnyFirestoreModel/geoPoint``
- ``AnyFirestoreModel/documentReference``
- ``AnyFirestoreModel/data``
- ``AnyFirestoreModel/array``
- ``AnyFirestoreModel/map``
