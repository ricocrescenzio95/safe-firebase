import Foundation
import FirebaseFirestore
@testable import SafeFirestore

@FirestoreModel
enum TestRole: String {
  case admin
  case member
}

@FirestoreModel
struct TestCoordinates {
  var latitude: Double
  var longitude: Double
}

@FirestoreModel
struct TestContact {
  var email: String
  var phone: String?
  var coordinates: TestCoordinates?
}

@FirestoreModel
struct TestSettings {
  var notificationsEnabled: Bool
  var refreshInterval: Int64
  var precision: Double
  var createdAt: Date
  var payload: Data
  var role: TestRole
}

@FirestoreModel
struct TestProfile {
  var name: String
  var city: String?
  var contact: TestContact?
  var settings: TestSettings
  var aliases: [String]?
  var flags: Set<String>

  @FirestoreExclude
  var localOnly: Int
}

@FirestoreCollection("users")
struct TestUser {
  var id: String
  var profile: TestProfile
  var nickname: String?
  var tags: Set<String>
  var optionalTags: Set<String>?
  var notes: [String]
  var metadata: [String: String]?
  var age: Int
  var optionalAge: Int?
}

@FirestoreCollection("aliased-users")
struct AliasedUser {
  var displayName: String
  var age: Int

  enum CodingKeys: String, CodingKey {
    case displayName = "display_name"
    case age
  }
}

@FirestoreModel
struct OperatorMatrixLeaf: Hashable {
  var score: Int
  var title: String?
  var labels: Set<String>
  var values: [Double]
}

@FirestoreModel
struct OperatorMatrixModel {
  var count: Int
  var optionalCount: Int?
  var enabled: Bool
  var optionalEnabled: Bool?

  var names: [String]
  var optionalScores: [Int]?
  var flags: Set<String>
  var optionalFlags: Set<String>?

  var leaf: OperatorMatrixLeaf
  var optionalLeaf: OperatorMatrixLeaf?
  var leaves: [String: OperatorMatrixLeaf]
  var optionalLeaves: [String: OperatorMatrixLeaf]?
  var leafArray: [OperatorMatrixLeaf]
  var optionalLeafArray: [OperatorMatrixLeaf]?
  var leafSet: Set<OperatorMatrixLeaf>
  var optionalLeafSet: Set<OperatorMatrixLeaf>?
  var mapValues: [String: Int]
  var mapArrays: [String: [Int]]
  var mapSets: [String: Set<String>]
  var nested: [String: [String: [String: Int]]]
  var optionalMap: [String: Int]?
}

@FirestoreModel
public struct PublicAccessModel {
  var internalValue: Int
  public var publicValue: String
}

@FirestoreModel
struct AllFirestoreNumericTypes: Equatable {
  var integer: Int
  var int64: Int64
  var int32: Int32
  var int16: Int16
  var int8: Int8
  var double: Double
  var float: Float
  var float16: Float16
}
