import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

struct Diagnostic: DiagnosticMessage {
  var diagnosticID: MessageID
  var message: String
  var severity: DiagnosticSeverity
}

func error(
  _ message: String,
  macro: Macro.Type,
  node: some SyntaxProtocol,
  context: some MacroExpansionContext,
  fixIts: [FixIt] = []
) {
  let id = MessageID(domain: String(describing: macro), id: UUID().uuidString)
  return context.diagnose(
    .init(
      node: node,
      message: Diagnostic(
        diagnosticID: id,
        message: message,
        severity: .error
      ),
      fixIts: fixIts.map {
        switch $0 {
        case .insert(let message, let changes): .init(message: FixItMessage(message: message, fixItID: id), changes: changes)
        case .replace(let message, let old, let new): .replace(message: FixItMessage(message: message, fixItID: id), oldNode: old, newNode: new)
        }
      }
    )
  )
}

enum FixIt {
  case replace(message: String, oldNode: SyntaxProtocol, newNode: SyntaxProtocol)
  case insert(message: String, [SwiftDiagnostics.FixIt.Change])
}

private struct FixItMessage: SwiftDiagnostics.FixItMessage {
  var message: String
  var fixItID: SwiftDiagnostics.MessageID
}

@main
struct CatalogBuilderMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    FirestoreModelMacro.self,
    FirestoreExcludeMacro.self,
  ]
}
