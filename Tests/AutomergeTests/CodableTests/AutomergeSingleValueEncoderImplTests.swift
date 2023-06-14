@testable import Automerge
import XCTest

final class AutomergeSingleValueEncoderImplTests: XCTestCase {
    var doc: Document!
    var singleValueContainer: SingleValueEncodingContainer!
    var cautiousSingleValueContainer: SingleValueEncodingContainer!

    enum SampleCodingKeys: String, CodingKey {
        case value
    }

    override func setUp() {
        doc = Document()
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("value")],
            doc: doc,
            strategy: .createWhenNeeded,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        let cautious = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("value")],
            doc: doc,
            strategy: .createWhenNeeded,
            cautiousWrite: true
        )
        cautiousSingleValueContainer = cautious.singleValueContainer()
    }

    func testSimpleKeyEncode_Bool() throws {
        try singleValueContainer.encode(true)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Boolean(true)))

        try cautiousSingleValueContainer.encode(false)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Boolean(false)))
    }

    func testSimpleKeyEncode_Bool_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(true)
        )
    }

    func testSimpleKeyEncode_Float() throws {
        try singleValueContainer.encode(Float(4.3))
        if case let .Scalar(.F64(floatValue)) = try doc.get(obj: ObjId.ROOT, key: "value") {
            XCTAssertEqual(floatValue, 4.3, accuracy: 0.01)
        } else {
            XCTFail("Scalar Float value not retrieved.")
        }

        try cautiousSingleValueContainer.encode(Float(3.4))
        if case let .Scalar(.F64(floatValue)) = try doc.get(obj: ObjId.ROOT, key: "value") {
            XCTAssertEqual(floatValue, 3.4, accuracy: 0.01)
        } else {
            XCTFail("Scalar Float value not retrieved.")
        }
    }

    func testSimpleKeyEncode_InvalidFloat() throws {
        XCTAssertThrowsError(
            try singleValueContainer.encode(Float.infinity)
        )
    }

    func testSimpleKeyEncode_InvalidDouble() throws {
        XCTAssertThrowsError(
            try singleValueContainer.encode(Double.nan)
        )
    }

    func testSimpleKeyEncode_Double_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .Int(40))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Double(3.4))
        )

        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Float(3.4))
        )
    }

    func testSimpleKeyEncode_Int8() throws {
        try singleValueContainer.encode(Int8(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))

        try cautiousSingleValueContainer.encode(Int8(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(5)))
    }

    func testSimpleKeyEncode_Int_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .String("40"))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Int(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Int8(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Int16(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Int32(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Int64(4))
        )
    }

    func testSimpleKeyEncode_Int16() throws {
        try singleValueContainer.encode(Int16(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))

        try cautiousSingleValueContainer.encode(Int16(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(5)))
    }

    func testSimpleKeyEncode_Int32() throws {
        try singleValueContainer.encode(Int32(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))

        try cautiousSingleValueContainer.encode(Int32(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(5)))
    }

    func testSimpleKeyEncode_Int64() throws {
        try singleValueContainer.encode(Int64(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(4)))

        try cautiousSingleValueContainer.encode(Int64(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Int(5)))
    }

    func testSimpleKeyEncode_UInt() throws {
        try singleValueContainer.encode(UInt(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousSingleValueContainer.encode(UInt(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(5)))
    }

    func testSimpleKeyEncode_UInt8() throws {
        try singleValueContainer.encode(UInt8(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousSingleValueContainer.encode(UInt8(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(5)))
    }

    func testSimpleKeyEncode_UInt16() throws {
        try singleValueContainer.encode(UInt16(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousSingleValueContainer.encode(UInt16(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(5)))
    }

    func testSimpleKeyEncode_UInt32() throws {
        try singleValueContainer.encode(UInt32(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousSingleValueContainer.encode(UInt32(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(5)))
    }

    func testSimpleKeyEncode_UInt64() throws {
        try singleValueContainer.encode(UInt64(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousSingleValueContainer.encode(UInt64(5))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(5)))
    }

    func testSimpleKeyEncode_UInt_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .String("40"))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(UInt(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(UInt8(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(UInt16(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(UInt32(4))
        )
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(UInt64(4))
        )
    }

    func testSimpleKeyEncode_Date() throws {
        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)
        try singleValueContainer.encode(earlyDate)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Timestamp(-905182980)))

        let anotherDate = try Date("1942-04-26T08:17:00Z", strategy: .iso8601)
        try cautiousSingleValueContainer.encode(anotherDate)
    }

    func testSimpleKeyEncode_Date_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .String("40"))
        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(earlyDate)
        )
    }

    func testSimpleKeyEncode_Data() throws {
        let data = Data("Hello".utf8)
        try singleValueContainer.encode(data)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Bytes(data)))

        try cautiousSingleValueContainer.encode(Data("World".utf8))
    }

    func testSimpleKeyEncode_Data_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .String("40"))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Data("World".utf8))
        )
    }

    func testSimpleKeyEncode_Text() throws {
        try singleValueContainer.encode(Text("hi"))
        let value = try doc.get(obj: ObjId.ROOT, key: "value")
        if case let .Object(objectId, .Text) = value {
            XCTAssertEqual(try doc.text(obj: objectId), "hi")
        } else {
            XCTFail("Expected Automerge text object")
        }
    }

    func testSimpleKeyEncode_Counter() throws {
        try singleValueContainer.encode(Counter(4))
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Counter(4)))

        try cautiousSingleValueContainer.encode(Counter(14))
    }

    func testSimpleKeyEncode_Counter_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .String("40"))
        XCTAssertThrowsError(
            try cautiousSingleValueContainer.encode(Counter(443))
        )
    }

    func testErrorEncode_Bool() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(true))
    }

    func testErrorEncode_Float() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Float(3.4)))
    }

    func testErrorEncode_Double() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Double(8.16)))
    }

    func testErrorEncode_Int() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Int(8)))
    }

    func testErrorEncode_Int8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Int8(8)))
    }

    func testErrorEncode_Int16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Int16(8)))
    }

    func testErrorEncode_Int32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Int32(8)))
    }

    func testErrorEncode_Int64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Int64(8)))
    }

    func testErrorEncode_UInt() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(UInt(8)))
    }

    func testErrorEncode_UInt8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(UInt8(8)))
    }

    func testErrorEncode_UInt16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(UInt16(8)))
    }

    func testErrorEncode_UInt32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(UInt32(8)))
    }

    func testErrorEncode_UInt64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(UInt64(8)))
    }

    func testErrorEncode_Text() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Text("hi")))
    }

    func testErrorEncode_Date() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        let earlyDate = try Date("1941-04-26T08:17:00Z", strategy: .iso8601)
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(earlyDate))
    }

    func testErrorEncode_Data() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere"), AnyCodingKey("value")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(Data("Hello".utf8)))
    }

    func testErrorEncode_Codable() throws {
        struct SimpleStruct: Codable {
            let a: String
        }

        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false
        )
        singleValueContainer = impl.singleValueContainer()
        XCTAssertThrowsError(try singleValueContainer.encode(SimpleStruct(a: "foo")))
    }
}
