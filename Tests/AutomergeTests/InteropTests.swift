@testable import Automerge
import Foundation
import XCTest

@available(macOS 12, *)
class InteropTests: XCTestCase {
    var markdownData: Data? = nil

    // DEVNOTE(heckj): Bundle based approaches for finding fixture files
    // work reasonably well with regular targets, but fail (or more specifically,
    // don't work as the docs assert) with resources embedded in test targets.
    //
    // As an alternative, this function returns the path URL to the **source files**
    // directory, which means that any tests relying on this function will only function
    // when run directly on the machine compiling all this stuff - for example, your mac
    //
    // This doesn't following the best practices asserting by Apple re: using URLs
    // to reference file paths, it's at least functional, short, and relatively easy
    // to understand if something goes awry.
    func fixturesDirectory(path: String = #file) -> URL {
        let url = URL(fileURLWithPath: path)
        let testsDir = url.deletingLastPathComponent()
        return testsDir.appendingPathComponent("Fixtures")
    }

    func dataFrom(resource: String) throws -> Data? {
        let urlForResource: URL
        if #available(macOS 13, *) {
            urlForResource = fixturesDirectory().appending(component: resource)
        } else {
            urlForResource = fixturesDirectory().appendingPathComponent(resource)
        }
        let data = try Data(contentsOf: urlForResource)
        return data
    }

    override func setUp() async throws {
        markdownData = try dataFrom(resource: "markdown.md")
    }

    func testFixtureFileLoad() throws {
        XCTAssertNotNil(markdownData)
    }

    func testAttributedStringParse() throws {
        let data = try XCTUnwrap(markdownData)
        let fancy = try AttributedString(markdown: data)
        XCTAssertNotNil(fancy)
        // print(fancy) // A basic print() provides a loose idea of runs within the multi-line output.
        let enc = JSONEncoder()
        let jsonencode = try enc.encode(fancy)
        print(String(bytes: jsonencode, encoding: .utf8) as Any)
        // custom encoders built in to foundation:
        // fancy.encode(to: Encoder, configuration: AttributeScopeCodableConfiguration)
        // see: https://developer.apple.com/documentation/foundation/decodableattributedstringkey
        // for some interesting details of what various Intents are provided by Apple that are
        // supported for encoding/decoding.
        //
        // https://developer.apple.com/documentation/foundation/inlinepresentationintent includes
        // code, emphasis, line-break, strike-through, strong, etc.
    }

    func testDescribeExistingPresentationIntents() throws {
        let foundation_presentation_types = [
            PresentationIntent.Kind.blockQuote,
            PresentationIntent.Kind.codeBlock(languageHint: "swift"),
            PresentationIntent.Kind.header(level: 1),
            PresentationIntent.Kind.listItem(ordinal: 1),
            PresentationIntent.Kind.orderedList,
            PresentationIntent.Kind.paragraph,
            PresentationIntent.Kind.table(
                columns:
                [
                    PresentationIntent.TableColumn(alignment: .left),
                    PresentationIntent.TableColumn(alignment: .center),
                    PresentationIntent.TableColumn(alignment: .right),
                ]
            ),
            PresentationIntent.Kind.tableCell(columnIndex: 1),
            PresentationIntent.Kind.tableHeaderRow,
            PresentationIntent.Kind.tableRow(rowIndex: 1),
            PresentationIntent.Kind.thematicBreak,
            PresentationIntent.Kind.unorderedList,
        ]
        let encoder = JSONEncoder()
        for type in foundation_presentation_types {
            let encoded = try encoder.encode(type)
            print("type: \(type.debugDescription) JSONencoded: \(String(data: encoded, encoding: .utf8) ?? "??")")
        }

        let inline_intents = [
            "blockHTML":
                InlinePresentationIntent.blockHTML,
            "code": InlinePresentationIntent.code,
            "emphasized": InlinePresentationIntent.emphasized,
            "inlineHTML": InlinePresentationIntent.inlineHTML,
            "lineBreak": InlinePresentationIntent.lineBreak,
            "softBreak": InlinePresentationIntent.softBreak,
            "strikethrough": InlinePresentationIntent.strikethrough,
            "stronglyEmphasized": InlinePresentationIntent.stronglyEmphasized,
        ]
        print("Inline Presentation Types")
        for (name, type) in inline_intents {
            print("type: \(name) rawValue: \(type.rawValue)")
        }
    }
}
