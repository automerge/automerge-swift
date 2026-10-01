@testable import Automerge
import XCTest

class TestScalarValueConversions: XCTestCase {
    func testScalarBooleanConversion() throws {
        let initial: ScalarValue = .Boolean(true)
        let converted: Bool = try Bool.fromScalarValue(initial).get()
        XCTAssertEqual(true, converted)

        XCTAssertThrowsError(try Bool.fromScalarValue(.Int(1)).get()) { error in
            XCTAssertError(error, is: BooleanScalarConversionError.self)
        }

        XCTAssertEqual(true.toScalarValue(), .Boolean(true))
    }

    func testScalarStringConversion() throws {
        let initial: ScalarValue = .String("hello")
        let converted: String = try String.fromScalarValue(initial).get()
        XCTAssertEqual("hello", converted)

        XCTAssertThrowsError(try String.fromScalarValue(.Int(1)).get()) { error in
            XCTAssertError(error, is: StringScalarConversionError.self)
        }

        XCTAssertEqual("hello".toScalarValue(), .String("hello"))
    }

    func testScalarBytesConversion() throws {
        let myData = "Hello There!".data(using: .utf8)!

        let initial: ScalarValue = .Bytes(myData)
        let converted: Data = try Data.fromScalarValue(initial).get()
        XCTAssertEqual(myData, converted)

        XCTAssertThrowsError(try Data.fromScalarValue(.Int(1)).get()) { error in
            XCTAssertError(error, is: BytesScalarConversionError.self)
        }

        XCTAssertEqual(myData.toScalarValue(), ScalarValue.Bytes(myData))
    }

    func testScalarUIntConversion() throws {
        let initial: ScalarValue = .Uint(5)
        let converted: UInt = try UInt.fromScalarValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try UInt.fromScalarValue(.String("1")).get()) { error in
            XCTAssertError(error, is: UIntScalarConversionError.self)
        }

        let explicitUInt: UInt = 5
        XCTAssertEqual(explicitUInt.toScalarValue(), ScalarValue.Uint(5))
    }

    func testScalarIntConversion() throws {
        let initial: ScalarValue = .Int(5)
        let converted: Int = try Int.fromScalarValue(initial).get()
        XCTAssertEqual(5, converted)

        XCTAssertThrowsError(try Int.fromScalarValue(.String("1")).get()) { error in
            XCTAssertError(error, is: IntScalarConversionError.self)
        }

        XCTAssertEqual(5.toScalarValue(), .Int(5))
    }

    func testScalarDoubleConversion() throws {
        let initial: ScalarValue = .F64(5)
        let converted: Double = try Double.fromScalarValue(initial).get()
        XCTAssertEqual(5.0, converted)

        XCTAssertThrowsError(try Double.fromScalarValue(.String("1")).get()) { error in
            XCTAssertError(error, is: FloatingPointScalarConversionError.self)
        }

        XCTAssertEqual(5.0.toScalarValue(), .F64(5))
    }

    func testScalarTimestampConversion() throws {
        let myDate = Date()

        let initial: ScalarValue = .Timestamp(myDate)
        let converted: Date = try Date.fromScalarValue(initial).get()
        XCTAssertEqual(myDate, converted)

        XCTAssertThrowsError(try Date.fromScalarValue(.String("1")).get()) { error in
            XCTAssertError(error, is: TimestampScalarConversionError.self)
        }

        XCTAssertEqual(myDate.toScalarValue(), .Timestamp(myDate))
    }
}
