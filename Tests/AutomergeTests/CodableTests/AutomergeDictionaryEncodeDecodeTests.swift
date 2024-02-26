import Automerge
import AutomergeUtilities
import XCTest

final class AutomergeDictionaryEncodeDecodeTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
    }

    func testFailingDictionaryEncodeDecode() throws {
        // example of Dictionary with keys other than a string

        struct Wrapper: Codable, Equatable {
            var exampleDictionary: [Int: String] = [:]
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        var wrapper = Wrapper()
        wrapper.exampleDictionary[1] = "one"
        wrapper.exampleDictionary[2] = "two"

        XCTExpectFailure("Automerge encoder can't encode keys other than strings.")
        try encoder.encode(wrapper)

        let replica = try decoder.decode(Wrapper.self)
        XCTAssertEqual(replica, wrapper)
    }

    func testEmptyDictionaryEncode() throws {
        var exampleDictionary: [String: Int] = [:]

        exampleDictionary["one"] = 1

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        try encoder.encode(exampleDictionary)

        let replica = try decoder.decode([String: Int].self)
        XCTAssertEqual(replica, exampleDictionary)
    }
}
