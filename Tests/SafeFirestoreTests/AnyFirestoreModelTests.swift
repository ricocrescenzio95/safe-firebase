import Foundation
import Testing
import FirebaseCore
import FirebaseFirestore
@testable import SafeFirestore

struct AnyFirestoreModelTests {
  @Test
  func representsEveryFirestoreModelCase() {
    let timestamp = Timestamp(date: Date(timeIntervalSince1970: 100))
    let values: [AnyFirestoreModel] = [
      .null,
      .bool(true),
      .int(42),
      .double(2.5),
      .string("Ada"),
      .timestamp(timestamp),
      .date(Date(timeIntervalSince1970: 200)),
      .geoPoint(GeoPoint(latitude: 41.9, longitude: 12.5)),
      .data(Data([0, 1, 2])),
      .array([.string("nested")]),
      .map(["nested": .bool(false)])
    ]

    #expect(values.count == 11)
    #expect(values[0].isNull)
    #expect(values[1].bool == true)
    #expect(values[2].int == 42)
    #expect(values[3].double == 2.5)
    #expect(values[4].string == "Ada")
    #expect(values[5].timestamp?.dateValue() == timestamp.dateValue())
    #expect(values[6].date == Date(timeIntervalSince1970: 200))
    #expect(values[7].geoPoint?.latitude == 41.9)
    #expect(values[7].geoPoint?.longitude == 12.5)
    #expect(values[8].data == Data([0, 1, 2]))
    #expect(values[9].array == [.string("nested")])
    #expect(values[10].map == ["nested": .bool(false)])
  }

  @Test
  func typedAccessorsReturnNilForNonMatchingCases() {
    let values: [AnyFirestoreModel] = [
      .null,
      .bool(true),
      .int(1),
      .double(1.0),
      .string("value"),
      .date(Date()),
      .data(Data())
    ]

    for value in values {
      if value != .bool(true) { #expect(value.bool == nil) }
      if value != .int(1) { #expect(value.int == nil) }
      if value != .string("value") { #expect(value.string == nil) }
    }

    #expect(!AnyFirestoreModel.bool(false).isNull)
    #expect(AnyFirestoreModel.map([:]).array == nil)
    #expect(AnyFirestoreModel.array([]).map == nil)
  }

  @Test
  func convertsNestedArraysAndMapsRecursively() {
    let value: AnyFirestoreModel = .map([
      "profile": .map([
        "name": .string("Ada"),
        "scores": .array([.int(10), .double(9.5)]),
        "active": .bool(true)
      ]),
      "empty": .array([]),
      "missing": .null
    ])

    let firestoreValue = value.firestoreValue as? [String: Any]
    let profile = firestoreValue?["profile"] as? [String: Any]
    let scores = profile?["scores"] as? [Any]

    #expect(profile?["name"] as? String == "Ada")
    #expect(scores?.compactMap { $0 as? Int64 } == [10])
    #expect(scores?.contains { ($0 as? Double) == 9.5 } == true)
    #expect(profile?["active"] as? Bool == true)
    #expect((firestoreValue?["empty"] as? [Any])?.isEmpty == true)
    #expect(firestoreValue?["missing"] is NSNull)
  }

  @Test
  func convertsNativeFirestoreModels() {
    let timestamp = Timestamp(date: Date(timeIntervalSince1970: 100))
    let date = Date(timeIntervalSince1970: 200)
    let point = GeoPoint(latitude: 41.9, longitude: 12.5)
    let data = Data([10, 20])

    #expect((AnyFirestoreModel.timestamp(timestamp).firestoreValue as? Timestamp)?.dateValue() == timestamp.dateValue())
    #expect(AnyFirestoreModel.date(date).firestoreValue as? Date == date)
    #expect((AnyFirestoreModel.geoPoint(point).firestoreValue as? GeoPoint)?.latitude == point.latitude)
    #expect(AnyFirestoreModel.data(data).firestoreValue as? Data == data)
    #expect(AnyFirestoreModel.null.firestoreValue is NSNull)
  }

  @Test
  func supportsCodableForScalarsAndNestedValues() throws {
    let values: [AnyFirestoreModel] = [
      .null,
      .bool(false),
      .int(-7),
      .double(3.25),
      .string("Firestore"),
      .array([.int(1), .map(["enabled": .bool(true)])]),
      .map(["name": .string("Ada"), "values": .array([.double(1.5), .null])])
    ]

    for value in values {
      let data = try JSONEncoder().encode(value)
      let decoded = try JSONDecoder().decode(AnyFirestoreModel.self, from: data)
      #expect(decoded == value)
    }
  }

  @Test
  func decodesComplexNestedJSONAsFirestoreModels() throws {
    let json = Data(#"""
    {
      "id": 42,
      "name": "Ada",
      "active": true,
      "score": 98.5,
      "deletedAt": null,
      "roles": ["admin", "reviewer"],
      "matrix": [[1, 2], [3, 4]],
      "projects": [
        {
          "name": "Safe Firebase",
          "labels": ["swift", "firestore"],
          "metadata": {
            "visibility": "private",
            "limits": {
              "read": 100,
              "write": 25
            }
          }
        }
      ],
      "settings": {
        "notifications": {
          "email": true,
          "push": false
        },
        "fallbacks": [
          {"region": "eu", "enabled": true},
          {"region": "us", "enabled": false}
        ]
      }
    }
    """#.utf8)

    let decoded = try JSONDecoder().decode(AnyFirestoreModel.self, from: json)

    let expected: AnyFirestoreModel = .map([
      "id": .int(42),
      "name": .string("Ada"),
      "active": .bool(true),
      "score": .double(98.5),
      "deletedAt": .null,
      "roles": .array([.string("admin"), .string("reviewer")]),
      "matrix": .array([
        .array([.int(1), .int(2)]),
        .array([.int(3), .int(4)])
      ]),
      "projects": .array([
        .map([
          "name": .string("Safe Firebase"),
          "labels": .array([.string("swift"), .string("firestore")]),
          "metadata": .map([
            "visibility": .string("private"),
            "limits": .map([
              "read": .int(100),
              "write": .int(25)
            ])
          ])
        ])
      ]),
      "settings": .map([
        "notifications": .map([
          "email": .bool(true),
          "push": .bool(false)
        ]),
        "fallbacks": .array([
          .map(["region": .string("eu"), "enabled": .bool(true)]),
          .map(["region": .string("us"), "enabled": .bool(false)])
        ])
      ])
    ])

    #expect(decoded == expected)
  }

  @Test
  func preservesEqualityAndHashabilityForNestedValues() {
    let first: AnyFirestoreModel = .map([
      "items": .array([.string("one"), .int(2)]),
      "enabled": .bool(true)
    ])
    let second: AnyFirestoreModel = .map([
      "enabled": .bool(true),
      "items": .array([.string("one"), .int(2)])
    ])

    #expect(first == second)
    #expect(Set([first, second]).count == 1)
  }

  @Test
  func convertsArraysOfArraysAndMapsOfMapsRecursively() throws {
    let nestedArrays: AnyFirestoreModel = .array([
      .array([.int(1), .int(2)]),
      .array([.array([.string("deep")])])
    ])
    let nestedMaps: AnyFirestoreModel = .map([
      "outer": .map([
        "inner": .map([
          "value": .string("nested"),
          "numbers": .array([.int(3), .int(4)])
        ])
      ])
    ])

    let convertedArrays = nestedArrays.firestoreValue as? [Any]
    let firstArray = convertedArrays?.first as? [Any]
    let secondArray = convertedArrays?[1] as? [Any]
    let deeplyNestedArray = secondArray?.first as? [Any]

    #expect(firstArray?.compactMap { $0 as? Int64 } == [1, 2])
    #expect(deeplyNestedArray?.compactMap { $0 as? String } == ["deep"])

    let convertedMaps = nestedMaps.firestoreValue as? [String: Any]
    let outerMap = convertedMaps?["outer"] as? [String: Any]
    let innerMap = outerMap?["inner"] as? [String: Any]

    #expect(innerMap?["value"] as? String == "nested")
    #expect((innerMap?["numbers"] as? [Any])?.compactMap { $0 as? Int64 } == [3, 4])

    let encoded = try JSONEncoder().encode(nestedMaps)
    let decoded = try JSONDecoder().decode(AnyFirestoreModel.self, from: encoded)
    #expect(decoded == nestedMaps)
  }

  @Test
  func supportsQueryOperatorsForTypeErasedValues() {
    let schema = AnyFirestoreModel.schema(path: ["payload"])

    #expect((schema == .string("ready")).operation == .equal(.string("ready")))
    #expect((schema != .null).operation == .notEqual(.null))
    #expect((schema > .int(10)).operation == .greater(.int(10)))
    #expect((schema <= .double(99.5)).operation == .lessOrEqual(.double(99.5)))
    let arraySchema = FirestoreSchema<[AnyFirestoreModel]>(_firestorePath: ["payload"])
    #expect(arraySchema.arrayContains(.string("swift")).operation == .arrayContains(.string("swift")))
    #expect(arraySchema.arrayContainsAny([.string("swift"), .string("firebase")]).operation == .arrayContainsAny([
      .string("swift"),
      .string("firebase")
    ]))
    #expect((arraySchema == [.string("swift"), .string("firebase")]).operation == .arrayEqual([
      .string("swift"),
      .string("firebase")
    ]))
    #expect(arraySchema.isIn([[.string("swift")]]).operation == .arrayIn([[.string("swift")]]))

    let mapSchema = FirestoreSchema<[String: AnyFirestoreModel]>(_firestorePath: ["payload", "metadata"])
    #expect((mapSchema == ["source": .string("test")]).operation == .mapEqual([
      "source": .string("test")
    ]))
    #expect((mapSchema["count"] >= .int(1)).path == [
      "payload",
      "metadata",
      "count"
    ])
  }

  @Test
  func exposesSchemaForNestedValuePaths() {
    let schema = AnyFirestoreModel.schema(path: ["payload"])
    let nested = schema["profile"]["name"]

    #expect(nested._firestorePath == ["payload", "profile", "name"])
  }
}
