@testable import Automerge
import XCTest

final class AutomergeKeyEncoderImplTests: XCTestCase {
    var doc: Document!
    var rootKeyedContainer: KeyedEncodingContainer<AutomergeKeyEncoderImplTests.SampleCodingKeys>!
    var cautiousKeyedContainer: KeyedEncodingContainer<AutomergeKeyEncoderImplTests.SampleCodingKeys>!

    enum SampleCodingKeys: String, CodingKey {
        case value
    }

    override func setUp() {
        doc = Document()
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [],
            doc: doc,
            strategy: .createWhenNeeded,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)

        let cautious = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [],
            doc: doc,
            strategy: .createWhenNeeded,
            cautiousWrite: true,
            logLevel: .errorOnly
        )
        cautiousKeyedContainer = cautious.container(keyedBy: SampleCodingKeys.self)
    }

    func testSimpleKeyEncode_Bool() throws {
        try rootKeyedContainer.encode(true, forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(true))

        try cautiousKeyedContainer.encode(false, forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(false))
    }

    func testSimpleKeyEncode_Bool_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: 4)
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(false, forKey: .value)
        )
    }

    func testSimpleKeyEncode_Float() throws {
        try rootKeyedContainer.encode(Float(4.3), forKey: .value)
        if case let .Scalar(.F64(floatValue)) = try doc.get(obj: ObjId.ROOT, key: "value") {
            XCTAssertEqual(floatValue, 4.3, accuracy: 0.01)
        } else {
            XCTFail("Scalar Float value not retrieved.")
        }

        try cautiousKeyedContainer.encode(Float(3.4), forKey: .value)
        try cautiousKeyedContainer.encode(Double(7.8), forKey: .value)
    }

    func testErrorEncode_Float() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Float(3.4), forKey: .value))
    }

    func testSimpleKeyEncode_InvalidFloat() throws {
        XCTAssertThrowsError(
            try rootKeyedContainer.encode(Float.infinity, forKey: .value)
        )
    }

    func testSimpleKeyEncode_InvalidDouble() throws {
        XCTAssertThrowsError(
            try rootKeyedContainer.encode(Double.nan, forKey: .value)
        )
    }

    func testSimpleKeyEncode_Float_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: 4)
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Float(4.0), forKey: .value)
        )
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Double(4.0), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int8() throws {
        try rootKeyedContainer.encode(Int8(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(4))

        try cautiousKeyedContainer.encode(Int8(5), forKey: .value)
    }

    func testSimpleKeyEncode_Int8_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Int8(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int16() throws {
        try rootKeyedContainer.encode(Int16(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(4))

        try cautiousKeyedContainer.encode(Int16(5), forKey: .value)
    }

    func testSimpleKeyEncode_Int16_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Int16(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int32() throws {
        try rootKeyedContainer.encode(Int32(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(4))

        try rootKeyedContainer.encode(Int32(5), forKey: .value)
    }

    func testSimpleKeyEncode_Int32_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Int32(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int64() throws {
        try rootKeyedContainer.encode(Int64(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(4))

        try cautiousKeyedContainer.encode(Int64(5), forKey: .value)
    }

    func testSimpleKeyEncode_Int64_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Int64(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Int_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Int(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_UInt() throws {
        try rootKeyedContainer.encode(UInt(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousKeyedContainer.encode(UInt(5), forKey: .value)
    }

    func testSimpleKeyEncode_UInt_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(UInt(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_UInt8() throws {
        try rootKeyedContainer.encode(UInt8(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousKeyedContainer.encode(UInt8(5), forKey: .value)
    }

    func testSimpleKeyEncode_UInt8_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(UInt8(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_UInt16() throws {
        try rootKeyedContainer.encode(UInt16(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))

        try cautiousKeyedContainer.encode(UInt16(5), forKey: .value)
    }

    func testSimpleKeyEncode_UInt16_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(UInt16(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_UInt32() throws {
        try rootKeyedContainer.encode(UInt32(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
        try cautiousKeyedContainer.encode(UInt32(5), forKey: .value)
    }

    func testSimpleKeyEncode_UInt32_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(UInt32(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_UInt64() throws {
        try rootKeyedContainer.encode(UInt64(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Uint(4)))
        try cautiousKeyedContainer.encode(UInt64(5), forKey: .value)
    }

    func testSimpleKeyEncode_UInt64_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(UInt64(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Counter() throws {
        try rootKeyedContainer.encode(Counter(4), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Counter(4)))

        try cautiousKeyedContainer.encode(Counter(45), forKey: .value)
    }

    func testSimpleKeyEncode_Counter_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(Counter(4), forKey: .value)
        )
    }

    func testSimpleKeyEncode_Data() throws {
        try rootKeyedContainer.encode(Data("Hello".utf8), forKey: .value)
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "value"), .Scalar(.Bytes(Data("Hello".utf8))))

        try cautiousKeyedContainer.encode(Data("World".utf8), forKey: .value)
    }

    func testSimpleKeyEncode_Date_CautiousFailure() throws {
        try doc.put(obj: ObjId.ROOT, key: "value", value: .F64(4.0))
        let dateFormatter = ISO8601DateFormatter()
        let earlyDate = dateFormatter.date(from: "1941-04-26T08:17:00Z")!
        XCTAssertThrowsError(
            try cautiousKeyedContainer.encode(earlyDate, forKey: .value)
        )
    }

    func testErrorEncode_Bool() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(true, forKey: .value))
    }

    func testErrorEncode_Double() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Double(8.16), forKey: .value))
    }

    func testErrorEncode_Int() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int(8), forKey: .value))
    }

    func testErrorEncode_Int8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int8(8), forKey: .value))
    }

    func testErrorEncode_Int16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int16(8), forKey: .value))
    }

    func testErrorEncode_Int32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int32(8), forKey: .value))
    }

    func testErrorEncode_Int64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(Int64(8), forKey: .value))
    }

    func testErrorEncode_UInt() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt(8), forKey: .value))
    }

    func testErrorEncode_UInt8() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt8(8), forKey: .value))
    }

    func testErrorEncode_UInt16() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt16(8), forKey: .value))
    }

    func testErrorEncode_UInt32() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt32(8), forKey: .value))
    }

    func testErrorEncode_UInt64() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [AnyCodingKey("nothere")],
            doc: doc,
            strategy: .readonly,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(UInt64(8), forKey: .value))
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
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        rootKeyedContainer = impl.container(keyedBy: SampleCodingKeys.self)
        XCTAssertThrowsError(try rootKeyedContainer.encode(SimpleStruct(a: "foo"), forKey: .value))
    }

    func testSuperEncoder() throws {
        let enc = rootKeyedContainer.superEncoder()
        XCTAssertEqual(enc.codingPath.count, 0)
    }

    func testSuperEncoderForKey() throws {
        let enc = rootKeyedContainer.superEncoder(forKey: .value)
        XCTAssertEqual(enc.codingPath.count, 0)
    }

    func testEncoderImplTreeBuilding() throws {
        let impl = AutomergeEncoderImpl(
            userInfo: [:],
            codingPath: [],
            doc: doc,
            strategy: .createWhenNeeded,
            cautiousWrite: false,
            logLevel: .errorOnly
        )
        // hand off to synthesized or provided logic
        let thingToEncode = Samples.layered
        try thingToEncode.encode(to: impl)
        // And we're back - see what we've got...

        // NOTE: change 'shouldPrint' to true if you want to see the
        // detail of the tree.
        walk(encoderImpl: impl, indent: 0, shouldPrint: false)

        func walk(encoderImpl: AutomergeEncoderImpl, indent: Int, shouldPrint: Bool) {
            let prefix = String(repeating: "  ", count: indent)
            // let compactCodingPath = encoderImpl.codingPath.stringPath()

            let compactCodingPath = encoderImpl.codingPath
                .map { pathElement in
                    AnyCodingKey(pathElement).description
                }
                .joined(separator: ".")

            switch encoderImpl.containerType {
            case .none:
                if shouldPrint { print("\(prefix)*NIL* - \(compactCodingPath)") }
                XCTFail("encountered encoderImpl without a defined type")
            case .some(.Index):
                if shouldPrint {
                    print(
                        "\(prefix)INDEX -> \(compactCodingPath) maxIndex: \(String(describing: encoderImpl.highestUnkeyedIndexWritten))"
                    )
                }
                XCTAssertNotNil(encoderImpl.highestUnkeyedIndexWritten)
                XCTAssertTrue(encoderImpl.mapKeysWritten.isEmpty)
                XCTAssertNotNil(encoderImpl.objectIdForContainer)
            case .some(.Key):
                if shouldPrint { print("\(prefix)KEY ---> \(compactCodingPath) keys: \(encoderImpl.mapKeysWritten)") }
                XCTAssertNil(encoderImpl.highestUnkeyedIndexWritten)
                XCTAssertFalse(encoderImpl.mapKeysWritten.isEmpty)
                XCTAssertNotNil(encoderImpl.objectIdForContainer)
            case .some(.Value):
                if shouldPrint { print("\(prefix)VALUE -> \(compactCodingPath)") }
                XCTAssertNotNil(encoderImpl.objectIdForContainer)
            }
            for child in encoderImpl.childEncoders {
                walk(encoderImpl: child, indent: indent + 1, shouldPrint: shouldPrint)
            }
        }
    }

    func testEncoderImplLimitedCleanup() throws {
        let fullEncoder = AutomergeEncoder(doc: doc)
        let fullDecoder = AutomergeDecoder(doc: doc)

        var thingToEncode = Samples.layered
        try fullEncoder.encode(thingToEncode)

        let decodedCopy = try fullDecoder.decode(ExampleModel.self)
        XCTAssertEqual(decodedCopy, thingToEncode)

        try fullEncoder.encode("Hello", at: [AnyCodingKey("title")])
        let newlyDecoded = try fullDecoder.decode(ExampleModel.self)
        XCTAssertEqual(newlyDecoded.notes.count, 12)
        XCTAssertNotEqual(newlyDecoded, thingToEncode)

        // change only Note 3 in the model
        thingToEncode.notes[3].description = "new description"
        let noteCopy = thingToEncode.notes[3]
        try fullEncoder.encode(noteCopy, at: [AnyCodingKey("notes"), AnyCodingKey(3)])

        let anotherDecoded = try fullDecoder.decode(ExampleModel.self)
        XCTAssertEqual(anotherDecoded.title, "Hello")
        XCTAssertEqual(anotherDecoded.notes[3], noteCopy)
        XCTAssertEqual(anotherDecoded.notes.count, 12)
    }
}
