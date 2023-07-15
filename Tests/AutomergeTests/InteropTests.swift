@testable import Automerge
import Foundation
import XCTest

@available(macOS 12, *)
class InteropTests: XCTestCase {
    var markdownData: Data? = nil
    #if os(macOS)
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
        let enc = JSONEncoder()
        let jsonencode = try enc.encode(fancy)
        print(String(bytes: jsonencode, encoding: .utf8))
        // print(fancy) // A basic print() provides a loose idea of runs within the multi-line output.
        //
        // custom encoders built in to foundation:
        // fancy.encode(to: Encoder, configuration: AttributeScopeCodableConfiguration)
        // see: https://developer.apple.com/documentation/foundation/decodableattributedstringkey
        // https://developer.apple.com/documentation/foundation/inlinepresentationintent includes
        // code, emphasis, line-break, strike-through, strong, etc.
    }
    #endif
}
