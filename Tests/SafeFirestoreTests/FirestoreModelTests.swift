import Foundation
import Testing
@testable import SafeFirestore
import FirebaseFirestore

struct FirestoreModelTests {
  @Test
  func firestoreValuesHandleOptionalValues() {
    let presentString: String? = "value"
    let missingString: String? = nil
    let presentDate: Date? = Date(timeIntervalSince1970: 10)
    let missingDate: Date? = nil
    
    #expect(presentString.firestoreValue as? String == "value")
    #expect(missingString.firestoreValue is NSNull)
    #expect(presentDate.firestoreValue as? Date == Date(timeIntervalSince1970: 10))
    #expect(missingDate.firestoreValue is NSNull)
  }

  @Test
  func firestoreValuesHandleNativeFirestoreTypes() {
    let point = GeoPoint(latitude: 41.9, longitude: 12.5)
    let timestamp = Timestamp(date: Date(timeIntervalSince1970: 100))
    let data = Data([10, 20])
    
    #expect((point.firestoreValue as? GeoPoint)?.latitude == 41.9)
    #expect((point.firestoreValue as? GeoPoint)?.longitude == 12.5)
    #expect((timestamp.firestoreValue as? Timestamp)?.dateValue() == timestamp.dateValue())
    #expect(data.firestoreValue as? Data == data)
  }

  @Test
  func rawRepresentableFirestoreModelUsesRawValue() {
    #expect(TestRole.admin.firestoreValue as? String == "admin")
    #expect(TestRole.member.firestoreValue as? String == "member")
  }

  @Test
  func firestoreValueCollectionsConvertRecursively() {
    let values: [String: [Int]] = ["numbers": [1, 2, 3]]
    let sets: Set<String> = ["admin", "editor"]
    let optionalMap: [String: Int]? = ["count": 4]
    let missingMap: [String: Int]? = nil
    
    let convertedValues = values.firestoreValue as? [String: [Any]]
    let convertedSets = sets.firestoreValue as? [Any]
    
    #expect(convertedValues?["numbers"]?.compactMap { $0 as? Int } == [1, 2, 3])
    #expect(Set(convertedSets?.compactMap { $0 as? String } ?? []) == sets)
    #expect((optionalMap.firestoreValue as? [String: Int])?["count"] == 4)
    #expect(missingMap.firestoreValue is NSNull)
  }

  @Test
  func firestoreValuesHandleAdditionalNumericTypes() {
    let int8: Int8 = -128
    let int16: Int16 = 32_000
    let int32: Int32 = 2_000_000_000
    let float: Float = 1.25
    let float16: Float16 = 2.5

    #expect(int8.firestoreValue as? Int8 == int8)
    #expect(int16.firestoreValue as? Int16 == int16)
    #expect(int32.firestoreValue as? Int32 == int32)
    #expect(float.firestoreValue as? Float == float)
    #expect(float16.firestoreValue as? Float16 == float16)

    assertFirestoreComparable(int8)
    assertFirestoreComparable(int16)
    assertFirestoreComparable(int32)
    assertFirestoreComparable(float)
    assertFirestoreComparable(float16)
  }

  @Test
  func firestoreEncoderAndDecoderRoundTripAllNumericTypes() throws {
    let original = AllFirestoreNumericTypes(
      integer: 42,
      int64: -9_000_000_000,
      int32: 2_000_000_000,
      int16: -30_000,
      int8: -120,
      double: 3.141592653589793,
      float: 1.25,
      float16: 2.5
    )

    let encoded = try Firestore.Encoder().encode(original)
    let decoded = try Firestore.Decoder().decode(
      AllFirestoreNumericTypes.self,
      from: encoded
    )

    #expect(decoded == original)
    #expect(encoded.keys.count == 8)
    #expect(encoded["integer"] != nil)
    #expect(encoded["int64"] != nil)
    #expect(encoded["int32"] != nil)
    #expect(encoded["int16"] != nil)
    #expect(encoded["int8"] != nil)
    #expect(encoded["double"] != nil)
    #expect(encoded["float"] != nil)
    #expect(encoded["float16"] != nil)
  }

  @Test
  func macroGeneratedFirestoreModelBuildsRecursiveMapAndExcludesProperties() {
    let leaf = OperatorMatrixLeaf(
      score: 7,
      title: "primary",
      labels: ["swift"],
      values: [0.5, 1.0]
    )
    let leafValue = leaf.firestoreValue as? [String: Any]

    #expect(leafValue?["score"] as? Int == 7)
    #expect(leafValue?["title"] as? String == "primary")
    #expect(leafValue?["labels"] as? [Any] != nil)
    #expect(leafValue?["values"] as? [Any] != nil)

    let profile = TestProfile(
      name: "Ada",
      city: nil,
      contact: nil,
      settings: TestSettings(
        notificationsEnabled: true,
        refreshInterval: 60,
        precision: 0.5,
        createdAt: Date(timeIntervalSince1970: 10),
        payload: Data([1, 2, 3]),
        role: .admin
      ),
      aliases: nil,
      flags: ["active"],
      localOnly: 123
    )
    let profileValue = profile.firestoreValue as? [String: Any]

    #expect(profileValue?["name"] as? String == "Ada")
    #expect(profileValue?["localOnly"] == nil)
    #expect(profileValue?["settings"] as? [String: Any] != nil)
  }

  private func assertFirestoreComparable<Value: FirestoreComparable>(_ value: Value) {
    #expect(Value.Schema(path: ["value"])._firestorePath == ["value"])
  }
}
