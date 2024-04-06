import Automerge
import XCTest

final class AutomergeDecoderTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()

        try! doc.put(obj: ObjId.ROOT, key: "name", value: .String("Joe"))
        try! doc.put(obj: ObjId.ROOT, key: "duration", value: .F64(3.14159))
        try! doc.put(obj: ObjId.ROOT, key: "flag", value: .Boolean(true))
        try! doc.put(obj: ObjId.ROOT, key: "count", value: .Int(5))
        try! doc.put(obj: ObjId.ROOT, key: "uuid", value: .String("99CEBB16-1062-4F21-8837-CF18EC09DCD7"))
        try! doc.put(obj: ObjId.ROOT, key: "url", value: .String("http://url.com"))
        try! doc.put(obj: ObjId.ROOT, key: "date", value: .Timestamp(Date(timeIntervalSince1970: 0)))
        try! doc.put(obj: ObjId.ROOT, key: "data", value: .Bytes(Data("hello".utf8)))

        let text = try! doc.putObject(obj: ObjId.ROOT, key: "notes", ty: .Text)
        setupCache["notes"] = text
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello")

        let votes = try! doc.putObject(obj: ObjId.ROOT, key: "votes", ty: .List)
        setupCache["votes"] = votes
        try! doc.insert(obj: votes, index: 0, value: .Int(3))
        try! doc.insert(obj: votes, index: 1, value: .Int(4))
        try! doc.insert(obj: votes, index: 2, value: .Int(5))

        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list

        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        setupCache["nestedMap"] = nestedMap

        try! doc.put(obj: nestedMap, key: "image", value: .Bytes(Data()))
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        setupCache["deeplyNestedText"] = deeplyNestedText
    }

    func testSimpleKeyDecode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
            let url: URL
            let notes: AutomergeText
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertNoThrow(try decoder.decode(SimpleStruct.self))

        let decodedStruct = try decoder.decode(SimpleStruct.self)

        XCTAssertEqual(decodedStruct.name, "Joe")
        XCTAssertEqual(decodedStruct.duration, 3.14159, accuracy: 0.0001)
        XCTAssertTrue(decodedStruct.flag)
        XCTAssertEqual(decodedStruct.count, 5)
        XCTAssertEqual(decodedStruct.url, URL(string: "http://url.com"))

        let expectedUUID = UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!
        XCTAssertEqual(decodedStruct.uuid, expectedUUID)

        let earlyDate = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(earlyDate, decodedStruct.date)
        XCTAssertEqual(Data("hello".utf8), decodedStruct.data)

        XCTAssertEqual("Hello", decodedStruct.notes.description)
    }

    func testDecodeTypeMismatch_propType() throws {
        struct SimpleStruct: Codable {
            let name: Double
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertThrowsError(try decoder.decode(SimpleStruct.self), "Expected type mismatch error") { _ in
            // print(error)
        }
    }

    func testDecodeTypeMismatch_list() throws {
        struct SimpleStruct: Codable {
            let name: [String]
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertThrowsError(try decoder.decode(SimpleStruct.self), "Expected type mismatch error") { _ in
            // print(error)
        }
    }

    func testDecodeTypeMismatch_key() throws {
        struct SimpleStruct: Codable {
            let votes: String
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertThrowsError(try decoder.decode(SimpleStruct.self), "Expected type mismatch error") { _ in
            // print(error)
        }
    }

    func testKeyAndListDecode() throws {
        struct StructWithArray: Codable {
            let name: String
            let votes: [Int]
        }
        let decoder = AutomergeDecoder(doc: doc)

        XCTAssertNoThrow(try decoder.decode(StructWithArray.self))

        let decodedStruct = try decoder.decode(StructWithArray.self)

        XCTAssertEqual(decodedStruct.name, "Joe")
        XCTAssertEqual(decodedStruct.votes, [3, 4, 5])
    }

    func testListOfTextDecode() throws {
        doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list
        let text0 = try! doc.insertObject(obj: list, index: 0, ty: .Text)
        try doc.spliceText(obj: text0, start: 0, delete: 0, value: "Hello?")
        let text1 = try! doc.insertObject(obj: list, index: 1, ty: .Text)
        try doc.spliceText(obj: text1, start: 0, delete: 0, value: "Hello!")

        struct ListOfText: Codable {
            let list: [AutomergeText]
        }

        let decoder = AutomergeDecoder(doc: doc)
        let decodedStruct = try decoder.decode(ListOfText.self)
        XCTAssertEqual(decodedStruct.list.count, 2)
        XCTAssertEqual(decodedStruct.list[0].description, "Hello?")
        XCTAssertEqual(decodedStruct.list[1].description, "Hello!")
    }
}
