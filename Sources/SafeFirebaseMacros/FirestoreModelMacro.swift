import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftBasicFormat
import SwiftSyntaxMacros

struct FirestoreModelMacro: ExtensionMacro {
  
  /// Attributes that exclude a property from the schema.
  /// Matched against the last component of the attribute name,
  /// so `@DocumentID` and `@FirebaseFirestore.DocumentID` are treated the same.
  private static let excludedAttributes: Set<String> = ["FirestoreExclude", "DocumentID"]

  /// Raw values supported by the standard FirestoreModel conformances.
  private static let supportedRawValueTypes: Set<String> = [
    "String", "Int", "Int8", "Int16", "Int32", "Int64",
    "Float", "Float16", "Double"
  ]
  
  private struct Property {
    let name: String
    let type: String
    let access: String
  }
  
  // MARK: - Expansion
  
  static func expansion(
    of node: AttributeSyntax,
    attachedTo decl: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let isFirestoreCollection = node.attributeName.trimmedDescription == "FirestoreCollection"
    
    if isFirestoreCollection {
      guard decl.as(StructDeclSyntax.self) != nil || decl.as(ClassDeclSyntax.self) != nil
      else {
        error(
          "@\(node.attributeName.trimmedDescription) can only be applied to a struct or class",
          macro: Self.self,
          node: decl,
          context: context
        )
        return []
      }
    } else {
      guard decl.as(StructDeclSyntax.self) != nil
        || decl.as(ClassDeclSyntax.self) != nil
        || decl.as(EnumDeclSyntax.self) != nil
      else {
        error(
          "@\(node.attributeName.trimmedDescription) can only be applied to a struct, class, or enum",
          macro: Self.self,
          node: decl,
          context: context
        )
        return []
      }
    }

    if let enumDecl = decl.as(EnumDeclSyntax.self) {
      guard let rawValueType = rawValueType(of: enumDecl) else {
        error(
          "@FirestoreModel enums must declare a supported raw value, or implement FirestoreModel manually",
          macro: Self.self,
          node: enumDecl,
          context: context
        )
        return []
      }

      let rawTypeName = rawValueType.split(separator: ".").last.map(String.init) ?? rawValueType
      guard supportedRawValueTypes.contains(rawTypeName) else {
        error(
          "Raw value type '\(rawValueType)' is not supported by @FirestoreModel; implement FirestoreModel manually",
          macro: Self.self,
          node: enumDecl,
          context: context
        )
        return []
      }
    }

    let access = memberAccess(of: decl.modifiers)
        
    var result: [ExtensionDeclSyntax] = [
      modelExtension(type: type, decl: decl, access: access, context: context)
    ]
    
    // `@FirestoreCollection` additionally conforms to `FirestoreCollection`
    if node.attributeName.trimmedDescription == "FirestoreCollection" {
      result += collectionExtension(
        node: node, type: type, decl: decl, access: access, context: context
      )
    }
    return result
  }
  
  // MARK: - Generated extensions

  /// Generates the `FirestoreModel` conformance and the nested schema type.
  private static func modelExtension(
    type: some TypeSyntaxProtocol,
    decl: some DeclGroupSyntax,
    access: String,
    context: some MacroExpansionContext
  ) -> ExtensionDeclSyntax {
    // One accessor per stored property. The compiler resolves `SchemaOf<T>`:
    // a `FirestoreSchema<T>` for Firestore values, a nested schema for models.
    let modelProperties = properties(of: decl, context: context)
    
    let accessorSources = modelProperties.map { p in
      """
      \(p.access)var \(p.name): SchemaOf<\(p.type)> {
        \(p.type).Schema(path: _firestorePath + [CodingKeys.\(p.name).stringValue])
      }
      """
    }

    let firestoreValues: String
    let isEnum = decl.as(EnumDeclSyntax.self) != nil
    if isEnum {
      firestoreValues = "rawValue.firestoreValue"
    } else {
      firestoreValues = modelProperties
        .map { p in
          "CodingKeys.\(p.name).stringValue: \(p.name).firestoreValue"
        }
        .joined(separator: ",\n")
    }

    let firestoreValueDeclaration = if isEnum {
      """
      \(access)var firestoreValue: Any {
        \(firestoreValues)
      }
      """
    } else {
      """
      \(access)var firestoreValue: Any {
        [
          \(firestoreValues)
        ]
      }
      """
    }

    let memberDeclarations: [DeclSyntax]
    if isEnum {
      let schemaTypealias = """
      \(access)typealias Schema = SafeFirestore::FirestoreSchema<Self>
      """
      memberDeclarations = [
        formattedDecl(firestoreValueDeclaration),
        formattedDecl(schemaTypealias, leadingNewlines: 2)
      ]
    } else {
      let schemaStruct = makeSchemaStruct(
        access: access,
        type: type.trimmedDescription,
        members: [
          "\(access)let _firestorePath: [String]",
          """
          \(access)init(path: [String] = []) {
            self._firestorePath = path
          }
          """
        ] + accessorSources
      )
      memberDeclarations = [
        formattedDecl(firestoreValueDeclaration),
        schemaStruct.with(\.leadingTrivia, .newlines(2))
      ]
    }

    return makeExtension(
      type: type,
      conformance: "SafeFirestore::FirestoreModel",
      members: memberDeclarations
    )
  }

  private static func rawValueType(of enumDecl: EnumDeclSyntax) -> String? {
    enumDecl.inheritanceClause?.inheritedTypes.first {
      let name = $0.type.trimmedDescription
      return name != "Codable" && name != "Encodable" && name != "Decodable"
    }?.type.trimmedDescription
  }
  
  /// Generates the `FirestoreCollection` conformance with the collection name.
  private static func collectionExtension(
    node: AttributeSyntax,
    type: some TypeSyntaxProtocol,
    decl: some DeclGroupSyntax,
    access: String,
    context: some MacroExpansionContext
  ) -> [ExtensionDeclSyntax] {
    let collection = node.arguments?
      .as(LabeledExprListSyntax.self)?
      .first?
      .expression
      .trimmedDescription
    
    // `trimmedDescription` of an empty string literal is `""` (two characters),
    // so it has to be checked explicitly.
    guard let collection, !collection.isEmpty, collection != "\"\"" else {
      error("Collection name cannot be empty", macro: Self.self, node: decl, context: context)
      return []
    }
    
    return [
      makeExtension(
        type: type,
        conformance: "SafeFirestore::FirestoreCollection",
        members: [formattedDecl("\(access)static var collectionName: String { \(collection) }")]
      )
    ]
  }
  
  private static func formattedDecl(
    _ source: String,
    leadingNewlines: Int = 0
  ) -> DeclSyntax {
    let declaration = DeclSyntax(stringLiteral: source)
      .formatted(using: BasicFormat(indentationWidth: .spaces(2)))
      .cast(DeclSyntax.self)

    guard leadingNewlines > 0 else { return declaration }
    return declaration.with(\.leadingTrivia, .newlines(leadingNewlines))
  }

  private static func makeSchemaStruct(
    access: String,
    type: String,
    members: [String]
  ) -> DeclSyntax {
    let memberBlock = MemberBlockSyntax(
      members: MemberBlockItemListSyntax(
        members.enumerated().map { index, member in
          MemberBlockItemSyntax(
            decl: formattedDecl(member, leadingNewlines: index >= 2 ? 2 : 0)
          )
        }
      )
    )

    let declaration = DeclSyntax(
      stringLiteral: "\(access)struct Schema: FirestoreSchemaProtocol<\(type)> {}"
    )
      .cast(StructDeclSyntax.self)
      .with(\.memberBlock, memberBlock)

    return declaration
      .formatted(using: BasicFormat(indentationWidth: .spaces(2)))
      .cast(DeclSyntax.self)
  }

  private static func makeExtension(
    type: some TypeSyntaxProtocol,
    conformance: String,
    members: [DeclSyntax]
  ) -> ExtensionDeclSyntax {
    let memberBlock = MemberBlockSyntax(
      members: MemberBlockItemListSyntax(
        members.map { MemberBlockItemSyntax(decl: $0) }
      )
    )

    let inheritanceClause = InheritanceClauseSyntax(
      inheritedTypes: InheritedTypeListSyntax([
        InheritedTypeSyntax(type: TypeSyntax(stringLiteral: conformance))
      ])
    )

    return ExtensionDeclSyntax(
      extendedType: type,
      inheritanceClause: inheritanceClause,
      memberBlock: memberBlock
    )
    .formatted(using: BasicFormat(indentationWidth: .spaces(2)))
    .cast(ExtensionDeclSyntax.self)
  }

  // MARK: - Access level

  /// Returns the explicit access level represented by a declaration's modifiers.
  /// An omitted or `internal` modifier is emitted without a keyword.
  private static func memberAccess(of modifiers: DeclModifierListSyntax) -> String {
    for modifier in modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.public), .keyword(.open):
        // `open` only exists for classes and their members: map it to `public`
        return "public "
      case .keyword(.package):
        return "package "
      case .keyword(.fileprivate), .keyword(.private):
        // A top-level `private` type is effectively `fileprivate`; a `private`
        // member inside an extension would be too restrictive.
        return "fileprivate "
      case .keyword(.internal):
        return ""
      default:
        continue
      }
    }
    return ""
  }
  
  // MARK: - Property collection
  
  private static func properties(
    of decl: some DeclGroupSyntax,
    context: some MacroExpansionContext
  ) -> [Property] {
    var result: [Property] = []
    
    for member in decl.memberBlock.members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
      
      // static / class properties are not part of the instance
      let isStatic = varDecl.modifiers.contains {
        $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
      }
      if isStatic { continue }
      
      // @FirestoreExclude, @DocumentID (also module-qualified)
      if isExcluded(varDecl) { continue }
      
      let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
      
      // In `var a, b: Int` the annotation is written only on the last binding
      // but applies to all the preceding bindings without an initializer.
      // Walk backwards to propagate it.
      var sharedType: TypeSyntax?
      var types: [TypeSyntax?] = []
      for binding in varDecl.bindings.reversed() {
        if let t = binding.typeAnnotation?.type {
          sharedType = t
          types.append(t)
        } else if binding.initializer == nil {
          types.append(sharedType)
        } else {
          types.append(nil)
        }
      }
      types.reverse()
      
      for (binding, type) in zip(varDecl.bindings, types) {
        // Computed properties are ignored by Codable and Firestore
        if isComputed(binding) { continue }
        
        // `let x = 5` is neither encoded nor decoded by Codable
        if isLet && binding.initializer != nil { continue }
        
        collect(
          pattern: binding.pattern,
          type: type,
          access: memberAccess(of: varDecl.modifiers),
          into: &result,
          context: context
        )
      }
    }
    return result
  }
  
  /// Walks a binding pattern together with its type, supporting tuple destructuring.
  /// Emits an error for anything that cannot be mapped, instead of silently
  /// dropping the property from the schema.
  private static func collect(
    pattern: PatternSyntax,
    type: TypeSyntax?,
    access: String,
    into result: inout [Property],
    context: some MacroExpansionContext
  ) {
    // var a: Int
    if let id = pattern.as(IdentifierPatternSyntax.self) {
      guard let type else {
        error(
          "Explicit type annotation required for '\(id.identifier.text)'",
          macro: Self.self, node: pattern, context: context
        )
        return
      }
      result.append(Property(
        name: id.identifier.trimmedDescription,
        type: typeText(type),
        access: access
      ))
      return
    }
    
    // var _: Int  ->  no property
    if pattern.is(WildcardPatternSyntax.self) { return }
    
    // var (a, b): (Int, String)  ->  recurse on matching elements
    if let tuplePattern = pattern.as(TuplePatternSyntax.self),
       let tupleType = type?.as(TupleTypeSyntax.self),
       tuplePattern.elements.count == tupleType.elements.count {
      for (p, t) in zip(tuplePattern.elements, tupleType.elements) {
        collect(
          pattern: p.pattern,
          type: t.type,
          access: access,
          into: &result,
          context: context
        )
      }
      return
    }
    
    error(
      "Unsupported property pattern: add explicit types matching the tuple structure",
      macro: Self.self, node: pattern, context: context
    )
  }
  
  private static func isExcluded(_ decl: VariableDeclSyntax) -> Bool {
    decl.attributes.contains { element in
      guard let attr = element.as(AttributeSyntax.self) else { return false }
      let name = attr.attributeName.trimmedDescription
      let last = name.split(separator: ".").last.map(String.init) ?? name
      return excludedAttributes.contains(last)
    }
  }
  
  private static func isComputed(_ binding: PatternBindingSyntax) -> Bool {
    guard let block = binding.accessorBlock else { return false }
    switch block.accessors {
    case .getter:
      return true  // var x: Int { ... }
    case .accessors(let list):
      // willSet/didSet are observers: the property is still stored
      return list.contains {
        $0.accessorSpecifier.tokenKind != .keyword(.willSet)
        && $0.accessorSpecifier.tokenKind != .keyword(.didSet)
      }
    }
  }
  
  /// `T!` cannot be used in `(T!).schema(...)`, so it is rewritten as `T?`.
  private static func typeText(_ type: TypeSyntax) -> String {
    if let iuo = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
      return "\(iuo.wrappedType.trimmedDescription)?"
    }
    return type.trimmedDescription
  }
}

/// No-op marker macro: `@FirestoreExclude` only needs to exist as a declaration;
/// `FirestoreModelMacro` reads the attribute from the syntax tree.
struct FirestoreExcludeMacro: PeerMacro {
  static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] { [] }
}
