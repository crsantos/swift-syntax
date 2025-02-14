import XCTest
import SwiftSyntax

public class VisitorTests: XCTestCase {
  public func testVisitMissingNodes() throws {
    let node = DeclarationStmtSyntax(declaration: DeclSyntax(MissingDeclSyntax(
      attributes: nil,
      modifiers: nil
    )))

    class MissingDeclChecker: SyntaxVisitor {
      var didSeeMissingDeclSyntax = false

      override func visit(_ node: MissingDeclSyntax) -> SyntaxVisitorContinueKind {
        didSeeMissingDeclSyntax = true
        return .visitChildren
      }

      static func check(_ tree: SyntaxProtocol, viewMode: SyntaxTreeViewMode) -> Bool {
        let visitor = MissingDeclChecker(viewMode: viewMode)
        visitor.walk(tree)
        return visitor.didSeeMissingDeclSyntax
      }
    }

    XCTAssertFalse(MissingDeclChecker.check(node, viewMode: .sourceAccurate))
    XCTAssertTrue(MissingDeclChecker.check(node, viewMode: .fixedUp))
  }

  public func testVisitUnexpected() throws {
    // This is just bunch of unexpected
    let unexpectedReturnStmt = ReturnStmtSyntax(
      UnexpectedNodesSyntax([Syntax(TokenSyntax.identifier("starting")), Syntax(TokenSyntax.integerLiteral("unexpected"))]),
      returnKeyword: .returnKeyword(trailingTrivia: [.spaces(1)]),
      UnexpectedNodesSyntax([Syntax(TokenSyntax.identifier("middle"))]),
      expression: ExprSyntax(NilLiteralExprSyntax(UnexpectedNodesSyntax([Syntax(TokenSyntax.identifier("end"))]), nilKeyword: TokenSyntax.nilKeyword(trailingTrivia: [])))
    )

    // This is more real-world where the user wrote null instead of nil.
    let misspelledNil = ReturnStmtSyntax(
      returnKeyword: .returnKeyword(trailingTrivia: [.spaces(1)]),
      expression: ExprSyntax(NilLiteralExprSyntax(
        UnexpectedNodesSyntax([Syntax(TokenSyntax.identifier("null"))]),
        nilKeyword: .nilKeyword(presence: .missing)
      ))
    )

    // Test SyntaxVisitor
    class TreePrinter: SyntaxVisitor {
      var out = ""

      override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        out += node.leadingTrivia.description
        out += node.text
        out += node.trailingTrivia.description
        return .visitChildren
      }

      static func print(_ tree: SyntaxProtocol, viewMode: SyntaxTreeViewMode) -> String {
        let printer = TreePrinter(viewMode: viewMode)
        printer.walk(tree)
        return printer.out
      }
    }

    XCTAssertEqual(TreePrinter.print(unexpectedReturnStmt, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(TreePrinter.print(unexpectedReturnStmt, viewMode: .sourceAccurate), "startingunexpectedreturn middleendnil")

    XCTAssertEqual(TreePrinter.print(misspelledNil, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(TreePrinter.print(misspelledNil, viewMode: .sourceAccurate), "return null")

    // Test SyntaxAnyVisitor
    class AnyTreePrinter: SyntaxAnyVisitor {
      var out = ""

      override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if let token = node.as(TokenSyntax.self) {
          out += token.leadingTrivia.description
          out += token.text
          out += token.trailingTrivia.description
        }
        return .visitChildren
      }


      static func print(_ tree: SyntaxProtocol, viewMode: SyntaxTreeViewMode) -> String {
        let printer = TreePrinter(viewMode: viewMode)
        printer.walk(tree)
        return printer.out
      }
    }

    XCTAssertEqual(AnyTreePrinter.print(unexpectedReturnStmt, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(AnyTreePrinter.print(unexpectedReturnStmt, viewMode: .sourceAccurate), "startingunexpectedreturn middleendnil")

    XCTAssertEqual(AnyTreePrinter.print(misspelledNil, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(AnyTreePrinter.print(misspelledNil, viewMode: .sourceAccurate), "return null")

    // Test SyntaxRewriter
    class RewritingTreePrinter: SyntaxRewriter {
      var out = ""

      override func visit(_ node: TokenSyntax) -> Syntax {
        out += node.leadingTrivia.description
        out += node.text
        out += node.trailingTrivia.description
        return Syntax(node)
      }


      static func print(_ tree: SyntaxProtocol, viewMode: SyntaxTreeViewMode) -> String {
        let printer = TreePrinter(viewMode: viewMode)
        printer.walk(tree)
        return printer.out
      }
    }

    XCTAssertEqual(RewritingTreePrinter.print(unexpectedReturnStmt, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(RewritingTreePrinter.print(unexpectedReturnStmt, viewMode: .sourceAccurate), "startingunexpectedreturn middleendnil")

    XCTAssertEqual(RewritingTreePrinter.print(misspelledNil, viewMode: .fixedUp), "return nil")
    XCTAssertEqual(RewritingTreePrinter.print(misspelledNil, viewMode: .sourceAccurate), "return null")
  }
}
