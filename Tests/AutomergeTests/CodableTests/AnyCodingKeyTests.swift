
@testable import Automerge
import XCTest

final class AnyCodingKeyTests: XCTestCase {
    func testPathParsing() throws {
        let empty = try AnyCodingKey.parsePath("")
        XCTAssertEqual(empty, [])

        XCTAssertThrowsError(try AnyCodingKey.parsePath("/"))

        let single = try AnyCodingKey.parsePath("list")
        XCTAssertEqual(single, [AnyCodingKey("list")])

        XCTAssertThrowsError(try AnyCodingKey.parsePath("1"))

        let singleInt = try AnyCodingKey.parsePath("[1]")
        XCTAssertEqual(singleInt, [AnyCodingKey(1)])

        XCTAssertThrowsError(try AnyCodingKey.parsePath("[]"))

        XCTAssertThrowsError(try AnyCodingKey.parsePath("[foo]"))

        let sequence = try AnyCodingKey.parsePath(".list.[45].notes")
        XCTAssertEqual(sequence.count, 3)
        XCTAssertEqual(sequence[0].stringValue, "list")
        XCTAssertNil(sequence[0].intValue)
        XCTAssertEqual(sequence[1].intValue, 45)
        XCTAssertEqual(sequence[2].stringValue, "notes")
        XCTAssertNil(sequence[2].intValue)
    }

    func testAnyCodingKeyDescription() throws {
        let one = AnyCodingKey("list")
        XCTAssertNil(one.intValue)
        XCTAssertEqual(one.description, "list")
        let two = AnyCodingKey(5)
        XCTAssertNotNil(two.intValue)
        XCTAssertEqual(two.description, "[5]")
    }

    func testDescriptionParseRoundTrip() throws {
        let examplePath: [any CodingKey] = [
            AnyCodingKey("list"),
            AnyCodingKey(5),
            AnyCodingKey("notes"),
        ]

        let strPath = examplePath.stringPath()
        XCTAssertEqual(strPath, ".list.[5].notes")

        let parsedResult = try AnyCodingKey.parsePath(strPath)
        XCTAssertEqual(parsedResult.count, examplePath.count)
    }
}
