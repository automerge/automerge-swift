@testable import Automerge
import XCTest

final class Document_PathElementConversionTests: XCTestCase {
    func testPathElementListToPath() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        let pathToList = try! doc.path(obj: nestedMap)
        XCTAssertEqual(
            pathToList,
            [
                PathElement(
                    obj: ObjId.ROOT,
                    prop: .Key("list")
                ),
                PathElement(
                    obj: list,
                    prop: .Index(0)
                ),
            ]
        )
        XCTAssertEqual(pathToList.stringPath(), ".list.[0]")

        let pathToText = try! doc.path(obj: deeplyNestedText)
        // print("textPath: \(pathToText)")
        XCTAssertEqual(
            pathToText,
            [
                PathElement(
                    obj: ObjId.ROOT,
                    prop: .Key("list")
                ),
                PathElement(
                    obj: list,
                    prop: .Index(0)
                ),
                PathElement(
                    obj: nestedMap,
                    prop: .Key("notes")
                ),
            ]
        )

        XCTAssertEqual(pathToText.stringPath(), ".list.[0].notes")
    }

    func testPathElementListToAnyCodingKey() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        let pathToList = try! doc.path(obj: deeplyNestedText)
        XCTAssertEqual(pathToList.count, 3)

        let converted = pathToList.map { AnyCodingKey($0) }
        XCTAssertEqual(converted.count, 3)

        XCTAssertEqual(pathToList.stringPath(), converted.stringPath())
        XCTAssertEqual(converted.stringPath(), ".list.[0].notes")
    }
}
