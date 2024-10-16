#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import Automerge
import Foundation
import XCTest

extension Data {
    /// Returns the data as a hex-encoded string.
    /// - Parameter uppercase: A Boolean value that indicates whether the hex encoded string uses uppercase letters.
    func hexEncodedString(uppercase: Bool = false) -> String {
        let format = uppercase ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

@available(macOS 12, iOS 16, *)
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

    struct ExemplarStructure: Codable, Equatable {
        var title: String
        var notes: AutomergeText
        var timestamp: Date
        var location: URL
        var counter: Counter
        var int: Int
        var uint: UInt
        var fp: Double
        var bytes: Data
        var bool: Bool
    }

    func testExemplarAutomergeDocRepresentations() throws {
        guard let data = try dataFrom(resource: "exemplar") else {
            XCTFail("Unable to load exemplar fixture")
            return
        }
        let doc = try Document(data)
        let decoder = AutomergeDecoder(doc: doc)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        let expectedDate = formatter.date(from: "1941-04-26T08:17:01.000Z")

        let magicValue = "856f4a83"
        // hex values for the magic value of an Automerge document

        let exemplar = try decoder.decode(ExemplarStructure.self)

        XCTAssertEqual(exemplar.timestamp, expectedDate)
        XCTAssertEqual(exemplar.title, "Hello 🇬🇧👨‍👨‍👧‍👦😀")
        XCTAssertEqual(exemplar.notes.value, "🇬🇧👨‍👨‍👧‍👦😀")
        XCTAssertEqual(exemplar.location, URL(string: "https://automerge.org/")!)
        XCTAssertEqual(exemplar.counter.value, 5)
        XCTAssertEqual(exemplar.int, -4)
        XCTAssertEqual(exemplar.uint, UInt(UInt64.max))
        XCTAssertEqual(exemplar.fp, 3.14159267, accuracy: 0.0000001)
        XCTAssertEqual(exemplar.bytes.hexEncodedString(), magicValue)
        XCTAssertEqual(exemplar.bool, true)
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
}
#endif
