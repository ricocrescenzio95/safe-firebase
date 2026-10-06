import Foundation
import Testing
@testable import SafeFirestore
import MetaCodable
import FirebaseFirestore

struct SchemaTests {
  @Test
  func collectionMetadataAndDeeplyNestedSchemaUseCodingKeys() {
    let schema = TestUser.schema(path: [])
    
    #expect(TestUser.collectionName == "users")
    #expect((schema.id == "user-1").path == ["id"])
    #expect((schema.profile.name == "Ada").path == ["profile", "name"])
    #expect((schema.profile.city != "Rome").path == ["profile", "city"])
    #expect((schema.profile.contact.email == "ada@example.com").path == ["profile", "contact", "email"])
    #expect((schema.profile.contact.phone == "+39").path == ["profile", "contact", "phone"])
    #expect((schema.profile.contact.coordinates.latitude > 40.0).path == [
      "profile", "contact", "coordinates", "latitude"
    ])
    #expect((schema.profile.settings.role == .admin).path == ["profile", "settings", "role"])
    #expect((schema.profile.settings.createdAt >= Date(timeIntervalSince1970: 0)).path == [
      "profile", "settings", "createdAt"
    ])
    #expect((schema.profile.aliases == ["ada", "a"]).path == ["profile", "aliases"])
  }

  @Test
  func schemaSupportsDifferentFirestoreValueTypes() {
    let schema = TestUser.schema(path: [])
    
    #expect((schema.profile.settings.notificationsEnabled == true).operation == .equal(true))
    #expect((schema.profile.settings.refreshInterval >= Int64(900)).operation == .greaterOrEqual(900))
    #expect((schema.profile.settings.precision < 0.01).operation == .less(0.01))
    #expect((schema.profile.settings.createdAt > Date(timeIntervalSince1970: 100)).operation == .greater(
      Date(timeIntervalSince1970: 100)
    ))
    #expect((schema.profile.settings.role == .member).operation == .equal(.member))
  }

  @Test
  func schemaUsesCustomCodingKeysForFirestorePaths() {
    let schema = AliasedUser.schema(path: [])

    #expect(AliasedUser.collectionName == "aliased-users")
    #expect((schema.displayName == "Ada").path == ["display_name"])
    #expect((schema.age >= 18).path == ["age"])
  }

  @Test
  func schemaExcludesPropertiesMarkedWithFirestoreExclude() {
    let schema = TestProfile.schema(path: [])
    
    #expect((schema.name == "Ada").path == ["name"])
    #expect((schema.city == "Rome").path == ["city"])
    #expect((schema.flags.arrayContains("trusted")).path == ["flags"])
  }

  @Test
  func schemaPathsSupportKeyPathsAndDynamicMembers() {
    let schema = TestUser.schema(path: [])
    
    let keyPathField = DocumentDataField<TestUser>(\.profile.contact.coordinates.longitude)
    let closureField = DocumentDataField<TestUser>({ $0.profile.contact.coordinates.longitude })
    
    #expect(keyPathField.path == "profile.contact.coordinates.longitude")
    #expect(closureField.path == keyPathField.path)
    #expect((schema.profile.contact.coordinates.longitude == 12.5).path == [
      "profile",
      "contact",
      "coordinates",
      "longitude"
    ])
    #expect((schema.profile.contact[keyPath: \.email] == "ada@example.com").path == [
      "profile",
      "contact",
      "email"
    ])
  }

  @Test
  func optionalAndNestedCollectionSchemasPreservePaths() {
    let schema = OperatorMatrixModel.schema(path: [])
    
    #expect(schema.optionalLeaf.title.isNotNull.path == [
      "optionalLeaf",
      "title"
    ])
    #expect(schema.optionalLeafArray._firestorePath == ["optionalLeafArray"])
    #expect(schema.leaves._firestorePath == ["leaves"])
    #expect(schema.optionalLeaves._firestorePath == ["optionalLeaves"])
    #expect(schema.mapArrays._firestorePath == ["mapArrays"])
    #expect(schema.mapSets._firestorePath == ["mapSets"])
  }

  @Test
  func macroGeneratedSchemaCompilesWithMixedAccessModifiers() {
    let schema = PublicAccessModel.schema(path: [])
    
    #expect((schema.internalValue == 1).path == ["internalValue"])
    #expect((schema.publicValue == "value").path == ["publicValue"])
  }
}
