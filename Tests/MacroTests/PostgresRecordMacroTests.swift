@testable import PostgresRecordMacro
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PostgresRecordMacroTests: XCTestCase {

    func test() throws {
        assertMacroExpansion("""
            @PostgresRecord
            public struct MyTable {
                let int: Int
                let string: String?
            }
            """,
            expandedSource: #"""
            public struct MyTable {
                let int: Int
                let string: String?
            }

            extension MyTable: PostgresRecord {
                public init(
                    _from row: PostgresRow,
                    context: PostgresDecodingContext<some PostgresJSONDecoder>,
                    file: String,
                    line: Int
                ) throws {
                    let decoded = try row.decode(
                        (Int, String?).self,
                        context: context,
                        file: file,
                        line: line
                    )
                    self.int = decoded.0
                    self.string = decoded.1
                }
            }
            """#,
            macros: PostgresRecordMacroEntryPoint.macros
        )
    }

    func testOnlyAllowsStructs() {
        assertMacroExpansion("""
            @PostgresRecord
            enum MyTable {
                case a
            }
            """,
            expandedSource: #"""

            enum MyTable {
                case a
            }
            """#,
            diagnostics: [
                .init(
                    message: "Only 'struct's are supported",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: PostgresRecordMacroEntryPoint.macros
        )
    }

    func testDoesNotAllowSimultaneousConformance() {
        assertMacroExpansion("""
            @PostgresRecord
            struct MyTable: PostgresDecodable {
                let thing: String
            }
            """,
            expandedSource: #"""

            struct MyTable: PostgresDecodable {
                let thing: String
            }
            """#,
            diagnostics: [
                .init(
                    message: "Simultaneous conformance to 'PostgresDecodable' is not supported",
                    line: 1,
                    column: 1,
                    severity: .error,
                    highlight: nil,
                    notes: [],
                    fixIts: [.init(
                        message: "Remove conformance to 'PostgresDecodable'"
                    )]
                )
            ],
            macros: PostgresRecordMacroEntryPoint.macros
        )
    }
}
