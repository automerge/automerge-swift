import Automerge
import XCTest

final class AutomergeTargettedEncodeDecodeTests: XCTestCase {
    func testSimpleKeyEncode() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        struct SimpleStruct: Codable, Equatable {
            let name: String
            let notes: AutomergeText
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)
        let automergeDecoder = AutomergeDecoder(doc: doc)

        let sample = SimpleStruct(
            name: "henry",
            notes: AutomergeText("Something wicked this way comes.")
        )

        let pathToTry: [AnyCodingKey] = [
            AnyCodingKey("example"),
            AnyCodingKey(0),
        ]
        try automergeEncoder.encode(sample, at: pathToTry)

        XCTAssertNotNil(try doc.get(obj: ObjId.ROOT, key: "example"))
        let foo = try doc.lookupPath(path: ".example.[0]")
        XCTAssertNotNil(foo)

        let decodedStruct = try automergeDecoder.decode(SimpleStruct.self, from: pathToTry)
        XCTAssertEqual(decodedStruct, sample)
    }

    func testTargetedSingleValueDecode() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        struct SimpleStruct: Codable, Equatable {
            let name: String
            let notes: AutomergeText
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)
        let automergeDecoder = AutomergeDecoder(doc: doc)

        let sample = SimpleStruct(
            name: "henry",
            notes: AutomergeText("Something wicked this way comes.")
        )

        let pathToTry: [AnyCodingKey] = [
            AnyCodingKey("example"),
            AnyCodingKey(0),
        ]
        try automergeEncoder.encode(sample, at: pathToTry)

        let decoded1 = try automergeDecoder.decode(String.self, from: AnyCodingKey.parsePath("example.[0].name"))
        XCTAssertEqual(decoded1, "henry")

        let decoded2 = try automergeDecoder.decode(
            AutomergeText.self,
            from: AnyCodingKey.parsePath("example.[0].notes")
        )
        XCTAssertEqual(decoded2.value, "Something wicked this way comes.")
    }

    func testTargetedDecodeOfData() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        let exampleData = Data("Hello".utf8)
        try doc.put(obj: ObjId.ROOT, key: "data", value: .Bytes(exampleData))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedData = try automergeDecoder.decode(Data.self, from: [AnyCodingKey("data")])
        XCTAssertEqual(decodedData, exampleData)
    }

    func testTargetedDecodeOfDate() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        let earlyDate = Date(timeIntervalSince1970: 0)
        try doc.put(obj: ObjId.ROOT, key: "date", value: .Timestamp(earlyDate))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedDate = try automergeDecoder.decode(Date.self, from: [AnyCodingKey("date")])
        XCTAssertEqual(decodedDate, earlyDate)
    }

    func testTargetedDecodeOfCounter() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        let exampleCounter = Counter(342)
        try doc.put(obj: ObjId.ROOT, key: "counter", value: .Counter(342))

        let automergeDecoder = AutomergeDecoder(doc: doc)
        let decodedCounter = try automergeDecoder.decode(Counter.self, from: [AnyCodingKey("counter")])
        XCTAssertEqual(decodedCounter, exampleCounter)
    }

    func testTargetedDecodeOfInts() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        try doc.put(obj: ObjId.ROOT, key: "int", value: .Int(34))

        let automergeDecoder = AutomergeDecoder(doc: doc)

        XCTAssertEqual(try automergeDecoder.decode(Int.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(Int64.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(Int8.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(Int16.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(Int32.self, from: [AnyCodingKey("int")]), 34)
    }

    func testTargetedDecodeOfUInts() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        try doc.put(obj: ObjId.ROOT, key: "int", value: .Uint(34))

        let automergeDecoder = AutomergeDecoder(doc: doc)

        XCTAssertEqual(try automergeDecoder.decode(UInt.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(UInt64.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(UInt8.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(UInt16.self, from: [AnyCodingKey("int")]), 34)
        XCTAssertEqual(try automergeDecoder.decode(UInt32.self, from: [AnyCodingKey("int")]), 34)
    }

    func testTargetedDecodeOfFloats() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        try doc.put(obj: ObjId.ROOT, key: "double", value: .F64(3.4))

        let automergeDecoder = AutomergeDecoder(doc: doc)

        XCTAssertEqual(try automergeDecoder.decode(Double.self, from: [AnyCodingKey("double")]), 3.4, accuracy: 0.1)
        XCTAssertEqual(try automergeDecoder.decode(Float.self, from: [AnyCodingKey("double")]), 3.4, accuracy: 0.1)
    }

    func testTargetedDecodeOfOptionalInt() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        try doc.put(obj: ObjId.ROOT, key: "int", value: .Int(34))

        let automergeDecoder = AutomergeDecoder(doc: doc)

        XCTAssertEqual(try automergeDecoder.decode(Int?.self, from: [AnyCodingKey("int")]), 34)
        let nothing = try automergeDecoder.decode(Int?.self, from: [AnyCodingKey("blarg")])
        XCTAssertNil(nothing)
    }
}
