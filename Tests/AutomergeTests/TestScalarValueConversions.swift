@testable import Automerge
import XCTest

class TestScalarValueConversions: XCTestCase {
    func testScalarBooleanConversion() throws {
        let initial: Value = .Scalar(.Boolean(true))
        let converted: Bool = try Bool.fromValue(initial).get()
        XCTAssertEqual(true, converted)

        XCTAssertThrowsError(try Bool.fromValue(.Scalar(.Int(1))).get())

        XCTAssertEqual(true.toScalarValue(), ScalarValue.Boolean(true))
    }

    func testScalarStringConversion() throws {
        let initial: Value = .Scalar(.String("hello"))
        let converted: String = try String.fromValue(initial).get()
        XCTAssertEqual("hello", converted)

        XCTAssertThrowsError(try String.fromValue(.Scalar(.Int(1))).get())

        XCTAssertEqual("hello".toScalarValue(), ScalarValue.String("hello"))
    }

    func testScalarBytesConversion() throws {
        let myData = "Hello There!".data(using: .utf8)!

        let initial: Value = .Scalar(.Bytes(myData))
        let converted: Data = try Data.fromValue(initial).get()
        XCTAssertEqual(myData, converted)

        XCTAssertThrowsError(try Data.fromValue(.Scalar(.Int(1))).get())

        XCTAssertEqual(myData.toScalarValue(), ScalarValue.Bytes(myData))
    }

    func testScalarUIntConversion() throws {
        let initial: Value = .Scalar(.Uint(5))
        let converted: UInt = try UInt.fromValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try Bool.fromValue(.Scalar(.Int(1))).get())

        let explicitUInt: UInt = 5
        XCTAssertEqual(explicitUInt.toScalarValue(), ScalarValue.Uint(5))
    }

    func testScalarIntConversion() throws {
        let initial: Value = .Scalar(.Int(5))
        let converted: Int = try Int.fromValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try Bool.fromValue(.Scalar(.Uint(1))).get())

        XCTAssertEqual(5.toScalarValue(), ScalarValue.Int(5))
    }

    func testScalarDoubleConversion() throws {
        let initial: Value = .Scalar(.F64(5))
        let converted: Double = try Double.fromValue(initial).get()
        XCTAssertEqual(5.0, converted)

        XCTAssertThrowsError(try Bool.fromValue(.Scalar(.Uint(1))).get())

        XCTAssertEqual(5.0.toScalarValue(), ScalarValue.F64(5))
    }

    func testScalarTimestampConversion() throws {
        let myDate = Date(timeIntervalSince1970: 1679517444)

        let initial: Value = .Scalar(.Timestamp(1679517444))
        let converted: Date = try Date.fromValue(initial).get()
        XCTAssertEqual(myDate, converted)

        XCTAssertThrowsError(try Bool.fromValue(.Scalar(.Uint(1))).get())

        XCTAssertEqual(myDate.toScalarValue(), ScalarValue.Timestamp(1679517444))
    }
}
