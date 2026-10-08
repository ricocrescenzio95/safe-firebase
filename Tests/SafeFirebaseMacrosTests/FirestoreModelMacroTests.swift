import SwiftSyntaxMacrosTestSupport
@testable import SafeFirebaseMacros
import Testing

private let macros = ["FirestoreModel": FirestoreModelMacro.self]

struct FirestoreModelMacroTests {
  @Test
  func modelOnStructUsesTwoSpaceIndentation() {
    assertMacroExpansion(
      """
      @FirestoreModel
      struct User {
          var name: String
      }
      """,
      expandedSource: """
      struct User {
          var name: String
      }
      
      extension User: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [
            CodingKeys.name.stringValue: name.firestoreValue
          ]
        }
      
        struct Schema: FirestoreSchemaProtocol<User> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
      
          var name: SchemaOf<String> {
            String.Schema(path: _firestorePath + [CodingKeys.name.stringValue])
          }
        }
      }
      """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
  
  @Test
  func modelOnClassGeneratesClassExpansion() {
    assertMacroExpansion(
      """
      @FirestoreModel
      final class Profile {
          var age: Int
      }
      """,
      expandedSource: """
      final class Profile {
          var age: Int
      }
      
      extension Profile: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [
            CodingKeys.age.stringValue: age.firestoreValue
          ]
        }
      
        struct Schema: FirestoreSchemaProtocol<Profile> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
      
          var age: SchemaOf<Int> {
            Int.Schema(path: _firestorePath + [CodingKeys.age.stringValue])
          }
        }
      }
      """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
  
  @Test
  func modelOnEnumUsesRawValue() {
    assertMacroExpansion(
      """
      @FirestoreModel
      enum Status: String {
          case active
      }
      """,
      expandedSource: """
      enum Status: String {
          case active
      }
      
      extension Status: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          rawValue.firestoreValue
        }
      
        typealias Schema = SafeFirestore::FirestoreSchema<Self>
      }
      """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }
  
  @Test
  func collectionOnStructGeneratesCollectionMetadata() {
    assertMacroExpansion(
      """
      @FirestoreCollection("users")
      struct User {
          var name: String
      }
      """,
      expandedSource: """
      struct User {
          var name: String
      }
      
      extension User: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [
            CodingKeys.name.stringValue: name.firestoreValue
          ]
        }
      
        struct Schema: FirestoreSchemaProtocol<User> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
      
          var name: SchemaOf<String> {
            String.Schema(path: _firestorePath + [CodingKeys.name.stringValue])
          }
        }
      }
      
      extension User: SafeFirestore::FirestoreCollection {
        static var collectionName: String {
          "users"
        }
      }
      """,
      macros: ["FirestoreCollection": FirestoreModelMacro.self],
      indentationWidth: .spaces(2)
    )
  }
  
  @Test
  func collectionOnClassGeneratesCollectionMetadata() {
    assertMacroExpansion(
      """
      @FirestoreCollection("profiles")
      final class Profile {
          var age: Int
      }
      """,
      expandedSource: """
      final class Profile {
          var age: Int
      }
      
      extension Profile: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [
            CodingKeys.age.stringValue: age.firestoreValue
          ]
        }
      
        struct Schema: FirestoreSchemaProtocol<Profile> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
      
          var age: SchemaOf<Int> {
            Int.Schema(path: _firestorePath + [CodingKeys.age.stringValue])
          }
        }
      }
      
      extension Profile: SafeFirestore::FirestoreCollection {
        static var collectionName: String {
          "profiles"
        }
      }
      """,
      macros: ["FirestoreCollection": FirestoreModelMacro.self],
      indentationWidth: .spaces(2)
    )
  }
  
  @Test
  func excludedFieldsAreOmittedFromSchemaAndFirestoreValue() {
    assertMacroExpansion(
      """
      @FirestoreModel
      struct Account {
          @FirestoreExclude var secret: String
          @DocumentID var id: String?
          var email: String
      }
      """,
      expandedSource: """
      struct Account {
          @FirestoreExclude var secret: String
          @DocumentID var id: String?
          var email: String
      }
      
      extension Account: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [
            CodingKeys.email.stringValue: email.firestoreValue
          ]
        }
      
        struct Schema: FirestoreSchemaProtocol<Account> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
      
          var email: SchemaOf<String> {
            String.Schema(path: _firestorePath + [CodingKeys.email.stringValue])
          }
        }
      }
      """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }

  @Test
  func modelReportsEnumWithoutRawValue() {
    assertMacroExpansion(
      """
      @FirestoreModel
      enum Status {
        case active
      }
      """,
      expandedSource: """
      enum Status {
        case active
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@FirestoreModel enums must declare a supported raw value, or implement FirestoreModel manually", line: 1, column: 1
        )
      ],
      macros: macros
    )
  }

  @Test
  func modelReportsUnsupportedEnumRawValue() {
    assertMacroExpansion(
      """
      @FirestoreModel
      enum Status: Bool {
        case active
      }
      """,
      expandedSource: """
      enum Status: Bool {
        case active
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "Raw value type 'Bool' is not supported by @FirestoreModel; implement FirestoreModel manually", line: 1, column: 1
        )
      ],
      macros: macros
    )
  }

  @Test
  func collectionReportsUnsupportedDeclaration() {
    assertMacroExpansion(
      """
      @FirestoreCollection("users")
      enum Status: String {
        case active
      }
      """,
      expandedSource: """
      enum Status: String {
        case active
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@FirestoreCollection can only be applied to a struct or class", line: 1, column: 1
        )
      ],
      macros: ["FirestoreCollection": FirestoreModelMacro.self]
    )
  }

  @Test
  func collectionReportsEmptyName() {
    assertMacroExpansion(
      """
      @FirestoreCollection("")
      struct User {}
      """,
      expandedSource: """
      struct User {}

      extension User: SafeFirestore::FirestoreModel {
        var firestoreValue: Any {
          [

          ]
        }

        struct Schema: FirestoreSchemaProtocol<User> {
          let _firestorePath: [String]
          init(path: [String] = []) {
            self._firestorePath = path
          }
        }
      }
      """,
      diagnostics: [
        DiagnosticSpec(message: "Collection name cannot be empty", line: 1, column: 1)
      ],
      macros: ["FirestoreCollection": FirestoreModelMacro.self]
    )
  }
}
