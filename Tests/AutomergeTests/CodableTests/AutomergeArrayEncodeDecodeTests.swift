import Automerge
import XCTest

final class AutomergeArrayEncodeDecodeTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
    }

    func testArrayShrinkingEncode() throws {
        // illustrates https://github.com/automerge/automerge-swift/issues/54

        struct StructWithArray: Codable, Equatable {
            var names: [String] = []
        }

        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)
        var sample = StructWithArray()
        sample.names.append("one")
        sample.names.append("two")

        try encoder.encode(sample)
        let replica = try decoder.decode(StructWithArray.self)
        XCTAssertEqual(replica, sample)

        _ = sample.names.popLast()
        try encoder.encode(sample)
        let secondReplica = try decoder.decode(StructWithArray.self)
        XCTAssertEqual(secondReplica, sample)
        // XCTAssertEqual failed:
        // ("StructWithArray(names: ["one", "one", "two"])") is not equal to
        // ("StructWithArray(names: ["one"])")
    }
}
