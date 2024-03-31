@testable import Automerge
import XCTest

class TestScalarValueConversions: XCTestCase {
    func testScalarBooleanConversion() throws {
        let initial: ScalarValue = .Boolean(true)
        let converted: Bool = try Bool.fromScalarValue(initial).get()
        XCTAssertEqual(true, converted)

        XCTAssertThrowsError(try Bool.fromScalarValue(.Int(1)).get())

        XCTAssertEqual(true.toScalarValue(), .Boolean(true))
    }

    func testScalarStringConversion() throws {
        let initial: ScalarValue = .String("hello")
        let converted: String = try String.fromScalarValue(initial).get()
        XCTAssertEqual("hello", converted)

        XCTAssertThrowsError(try String.fromScalarValue(.Int(1)).get())

        XCTAssertEqual("hello".toScalarValue(), .String("hello"))
    }

    func testScalarBytesConversion() throws {
        let myData = "Hello There!".data(using: .utf8)!

        let initial: ScalarValue = .Bytes(myData)
        let converted: Data = try Data.fromScalarValue(initial).get()
        XCTAssertEqual(myData, converted)

        XCTAssertThrowsError(try Data.fromScalarValue(.Int(1)).get())

        XCTAssertEqual(myData.toScalarValue(), ScalarValue.Bytes(myData))
    }

    func testScalarUIntConversion() throws {
        let initial: ScalarValue = .Uint(5)
        let converted: UInt = try UInt.fromScalarValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try UInt.fromScalarValue(.String("1")).get())

        let explicitUInt: UInt = 5
        XCTAssertEqual(explicitUInt.toScalarValue(), ScalarValue.Uint(5))
    }

    func testScalarIntConversion() throws {
        let initial: ScalarValue = .Int(5)
        let converted: Int = try Int.fromScalarValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try Int.fromScalarValue(.String("1")).get())

        XCTAssertEqual(5.toScalarValue(), .Int(5))
    }

    func testScalarDoubleConversion() throws {
        let initial: ScalarValue = .F64(5)
        let converted: Double = try Double.fromScalarValue(initial).get()
        XCTAssertEqual(5.0, converted)

        XCTAssertThrowsError(try Double.fromScalarValue(.String("1")).get())

        XCTAssertEqual(5.0.toScalarValue(), .F64(5))
    }

    func testScalarTimestampConversion() throws {
        let myDate = Date(timeIntervalSince1970: 1679517444)

        let initial: ScalarValue = .Timestamp(1679517444)
        let converted: Date = try Date.fromScalarValue(initial).get()
        XCTAssertEqual(myDate, converted)

        XCTAssertThrowsError(try Date.fromScalarValue(.String("1")).get())

        XCTAssertEqual(myDate.toScalarValue(), .Timestamp(1679517444))
    }
}
