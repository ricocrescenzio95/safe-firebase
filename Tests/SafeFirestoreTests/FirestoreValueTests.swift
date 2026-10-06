import Foundation
import Testing
@testable import SafeFirestore
import MetaCodable
import FirebaseFirestore

struct FirestoreValueTests {
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
  func rawRepresentableFirestoreValueUsesRawValue() {
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
}
