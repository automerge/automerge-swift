import Automerge
import XCTest

final class AutomergeKeyedEncoderDecoderTests: XCTestCase {
    var doc: Document!
    var encoder: AutomergeEncoder!
    var decoder: AutomergeDecoder!

    override func setUp() {
        doc = Document()
        encoder = AutomergeEncoder(doc: doc)
        decoder = AutomergeDecoder(doc: doc)
    }

    func testSimpleEncodeDecode() throws {
        struct SimpleStruct: Codable, Equatable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
            let null: Int?
            let notes: AutomergeText
        }

        let dateFormatter = ISO8601DateFormatter()
        let earlyDate = dateFormatter.date(from: "1941-04-26T08:17:00Z")!

        let sample = SimpleStruct(
            name: "henry",
            duration: 3.14159,
            flag: true,
            count: 5,
            date: earlyDate,
            data: Data("hello".utf8),
            uuid: UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!,
            null: nil,
            notes: AutomergeText("Something wicked this way comes.")
        )

        try encoder.encode(sample)
        let decodedStruct = try decoder.decode(SimpleStruct.self)

        XCTAssertEqual(sample, decodedStruct)
        XCTAssertTrue(decodedStruct.notes.isBound)
    }

    func testSimpleCounterEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let counter: Counter
        }

        let topLevel = WrapperStruct(counter: Counter(5))

        try encoder.encode(topLevel)
        // DEBUGGING ONLY - walks the whole document that's been encoded
        // try doc.walk()

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.counter.value, 5)
    }

    func testSimpleOptionalEncode() throws {
        struct WrapperStruct: Codable, Equatable {
            let counter: Counter?
            let string: String?

            // Needed because default implementation uses `encodeIfPresent` instead of `encode`.
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(counter, forKey: .counter)
                try container.encode(string, forKey: .string)
            }
        }

        let topLevel = WrapperStruct(counter: nil, string: nil)
        try encoder.encode(topLevel)
        XCTAssertEqual(try doc.get(obj: .ROOT, key: "counter"), .Scalar(.Null))
        XCTAssertEqual(try doc.get(obj: .ROOT, key: "string"), .Scalar(.Null))
    }

    func testSimpleOptionalCounterEncodeDecode() throws {
        doc = Document(logLevel: .tracing)
        struct WrapperStruct: Codable, Equatable {
            let counter: Counter?
            let anotherOptional: String?
        }

        let topLevel = WrapperStruct(counter: Counter(5), anotherOptional: nil)

        try encoder.encode(topLevel)

        // DEBUGGING ONLY - walks the whole document that's been encoded
        // try doc.walk()

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.counter?.value, 5)
        XCTAssertNil(decodedStruct.anotherOptional)
    }

    func testSimpleFloatEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Float
        }

        let topLevel = WrapperStruct(thing: 3.0)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3.0, decodedStruct.thing, accuracy: 0.1)
    }

    func testSimpleDoubleEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Double
        }

        let topLevel = WrapperStruct(thing: 3.0)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3.0, decodedStruct.thing, accuracy: 0.1)
    }

    func testSimpleInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Int8
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Int16
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Int32
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Int64
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Int
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleUInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: UInt8
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleUInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: UInt16
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleUInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: UInt32
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleUInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: UInt64
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleUIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: UInt
        }

        let topLevel = WrapperStruct(thing: 3)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(3, decodedStruct.thing)
    }

    func testSimpleDateEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Date
        }

        let dateFormatter = ISO8601DateFormatter()
        let earlyDate = dateFormatter.date(from: "1941-04-26T08:17:00Z")!
        let topLevel = WrapperStruct(thing: earlyDate)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(earlyDate, decodedStruct.thing)
    }

    func testSimpleDataEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: Data
        }

        let topLevel = WrapperStruct(thing: Data("Hello".utf8))

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(Data("Hello".utf8), decodedStruct.thing)
    }

    func testSimpleTextEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let thing: AutomergeText
        }

        let topLevel = WrapperStruct(thing: AutomergeText("hi"))
        XCTAssertFalse(topLevel.thing.isBound)

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual("hi", decodedStruct.thing.value)
        XCTAssertTrue(decodedStruct.thing.isBound)
    }
}
