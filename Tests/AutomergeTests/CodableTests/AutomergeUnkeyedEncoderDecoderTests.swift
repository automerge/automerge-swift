import Automerge
import XCTest

final class AutomergeUnkeyedEncoderDecoderTests: XCTestCase {
    var doc: Document!
    var encoder: AutomergeEncoder!
    var decoder: AutomergeDecoder!

    override func setUp() {
        doc = Document()
        encoder = AutomergeEncoder(doc: doc)
        decoder = AutomergeDecoder(doc: doc)
    }

    func testListOfSimpleEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [SimpleStruct]
        }

        struct SimpleStruct: Codable, Equatable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
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
            notes: AutomergeText("Something wicked this way comes.")
        )
        let topLevel = WrapperStruct(list: [sample])

        try encoder.encode(topLevel)

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(sample, decodedStruct.list.first)
    }

    func testListOfFloatEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Float]
        }

        let topLevel = WrapperStruct(list: [3.0])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3.0, decodedStruct.list.first!, accuracy: 0.1)
    }

    func testListOfDoubleEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Float]
        }

        let topLevel = WrapperStruct(list: [3.0])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3.0, decodedStruct.list.first!, accuracy: 0.1)
    }

    func testListOfInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int8]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int16]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int32]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int64]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Int]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt8EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt8]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt16EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt16]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt32EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt32]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUInt64EncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt64]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfUIntEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [UInt]
        }

        let topLevel = WrapperStruct(list: [3])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first)
    }

    func testListOfDateEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Date]
        }

        let dateFormatter = ISO8601DateFormatter()
        let earlyDate = dateFormatter.date(from: "1941-04-26T08:17:00Z")!
        let topLevel = WrapperStruct(list: [earlyDate])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(earlyDate, decodedStruct.list.first)
    }

    func testListOfDataEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Data]
        }

        let topLevel = WrapperStruct(list: [Data("Hello".utf8)])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(Data("Hello".utf8), decodedStruct.list.first)
    }

    func testListOfTextEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [AutomergeText]
        }

        let topLevel = WrapperStruct(list: [AutomergeText("hi")])

        try encoder.encode(topLevel)
        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual("hi", decodedStruct.list.first?.description)
    }

    func testListOfCounterEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [Counter]
        }

        let topLevel = WrapperStruct(list: [Counter(3)])

        try encoder.encode(topLevel)

        // try doc.walk()

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(3, decodedStruct.list.first?.value)
    }

    func testListOfURLEncodeDecode() throws {
        struct WrapperStruct: Codable, Equatable {
            let list: [URL]
        }

        let topLevel = WrapperStruct(list: [URL(string: "url.com")!])

        try encoder.encode(topLevel)

        let decodedStruct = try decoder.decode(WrapperStruct.self)
        XCTAssertEqual(decodedStruct.list.count, 1)
        XCTAssertEqual(decodedStruct.list, [URL(string: "url.com")!])
    }
}
