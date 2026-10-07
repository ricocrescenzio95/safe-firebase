import Foundation
import Testing
@testable import SafeFirestore
import FirebaseFirestore

struct DocumentDataTests {
  @Test
  func documentDataSupportsNestedScalarFields() {
    let email: DocumentData<TestUser> = .init({ $0.profile.contact.email }, "ada@example.com")
    let interval: DocumentData<TestUser> = .init({ $0.profile.settings.refreshInterval }, Int64(900))
    let enabled: DocumentData<TestUser> = .init({ $0.profile.settings.notificationsEnabled }, true)
    let precision: DocumentData<TestUser> = .init({ $0.profile.settings.precision }, 0.001)
    
    #expect(email.path == "profile.contact.email")
    #expect(email.value as? String == "ada@example.com")
    #expect(interval.path == "profile.settings.refreshInterval")
    #expect(interval.value as? Int64 == 900)
    #expect(enabled.path == "profile.settings.notificationsEnabled")
    #expect(enabled.value as? Bool == true)
    #expect(precision.path == "profile.settings.precision")
    #expect(precision.value as? Double == 0.001)
  }

  @Test
  func documentDataSupportsArraysAndSetsAtNestedPaths() {
    let aliases: DocumentData<TestUser> = .init({ $0.profile.aliases }, ["ada", "a"])
    let tags: DocumentData<TestUser> = .init({ $0.tags }, ["swift", "ios"])
    let flags: DocumentData<TestUser> = .init({ $0.profile.flags }, Set(["trusted", "verified"]))
    
    #expect(aliases.path == "profile.aliases")
    #expect((aliases.value as? [Any])?.compactMap { $0 as? String } == ["ada", "a"])
    #expect(tags.path == "tags")
    #expect(Set((tags.value as? [Any])?.compactMap { $0 as? String } ?? []) == ["swift", "ios"])
    #expect(flags.path == "profile.flags")
    #expect(Set((flags.value as? [Any])?.compactMap { $0 as? String } ?? []) == ["trusted", "verified"])
  }

  @Test
  func documentDataConvertsDateDataAndRawRepresentableValues() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let payload = Data([0, 1, 2, 3])
    let role = TestRole.admin
    
    let dateData: DocumentData<TestUser> = .init({ $0.profile.settings.createdAt }, date)
    let payloadData: DocumentData<TestUser> = .init({ $0.profile.settings.payload }, payload)
    let roleData: DocumentData<TestUser> = .init({ $0.profile.settings.role }, role)
    
    #expect(dateData.path == "profile.settings.createdAt")
    #expect(dateData.value as? Date == date)
    #expect(payloadData.path == "profile.settings.payload")
    #expect(payloadData.value as? Data == payload)
    #expect(roleData.path == "profile.settings.role")
    #expect(roleData.value as? String == "admin")
  }

  @Test
  func documentDataSupportsFirestoreTransforms() {
    let timestamp: DocumentData<TestUser> = .init(
      \.profile.settings.createdAt,
      FirestoreServerTimestamp<Date>()
    )
    let increment: DocumentData<TestUser> = .init(
      \.age,
      FirestoreIncrement<Int>(1)
    )
    let union: DocumentData<TestUser> = .init(
      \.tags,
      FirestoreArrayUnion(["swift", "firebase"])
    )
    let removal: DocumentData<TestUser> = .init(
      \.tags,
      FirestoreArrayRemove(["legacy"])
    )
    let deletion: DocumentData<TestUser> = .init(
      \.nickname,
      FirestoreDelete()
    )

    #expect(timestamp.path == "profile.settings.createdAt")
    #expect(timestamp.value is FieldValue)
    #expect(increment.path == "age")
    #expect(increment.value is FieldValue)
    #expect(union.path == "tags")
    #expect(union.value is FieldValue)
    #expect(removal.path == "tags")
    #expect(removal.value is FieldValue)
    #expect(deletion.path == "nickname")
    #expect(deletion.value is FieldValue)
  }

  @Test
  func documentDataSupportsOptionalMapsAndNestedArrays() {
    let map: DocumentData<OperatorMatrixModel> = .init(
      \.optionalMap,
       ["count": 42]
    )
    let nested: DocumentData<OperatorMatrixModel> = .init(
      \.nested,
       ["first": ["second": ["third": 7]]]
    )
    let optionalSet: DocumentData<TestUser> = .init(
      \.optionalTags,
       Set(["swift", "firebase"])
    )
    
    #expect(map.path == "optionalMap")
    #expect((map.value as? [String: Int])?["count"] == 42)
    #expect(nested.path == "nested")
    #expect(nested.value is [String: Any])
    #expect(optionalSet.path == "optionalTags")
    #expect(Set((optionalSet.value as? [Any])?.compactMap { $0 as? String } ?? []) == [
      "swift",
      "firebase"
    ])
  }
}
