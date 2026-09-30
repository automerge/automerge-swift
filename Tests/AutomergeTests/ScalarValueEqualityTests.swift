import Automerge
import AutomergeUtilities
import Foundation
import XCTest

class ScalarValueEqualityTests: XCTestCase {
    let nans: [Double] = [.nan, -.nan, .signalingNaN, Double(bitPattern: 0x7FF8_0000_0000_0001)]

    func testNaNEqualsNaNWhateverItsSignOrPayload() {
        for nan in nans {
            let label = "NaN with bit pattern \(String(nan.bitPattern, radix: 16))"
            XCTAssertEqual(ScalarValue.F64(nan), .F64(nan), label)
            XCTAssertEqual(ScalarValue.F64(nan), .F64(.nan), label)
            XCTAssertEqual(ScalarValue.F64(nan).hashValue, ScalarValue.F64(.nan).hashValue, label)
            XCTAssertEqual(Value.Scalar(.F64(nan)), .Scalar(.F64(.nan)), label)
        }
    }

    func testNaNDoesNotEqualNumbersAndOtherDoublesCompareAsDoubleDoes() {
        XCTAssertNotEqual(ScalarValue.F64(.nan), .F64(0))
        XCTAssertNotEqual(ScalarValue.F64(.nan), .F64(.infinity))
        XCTAssertEqual(ScalarValue.F64(-0.0), .F64(0.0))
        XCTAssertEqual(ScalarValue.F64(-0.0).hashValue, ScalarValue.F64(0.0).hashValue)
        XCTAssertNotEqual(ScalarValue.F64(1.5), .F64(1.25))
    }

    func testValuesOfDifferentTypesAreNeverEqual() {
        let values: [ScalarValue] = [
            .Bytes(Data()), .String(""), .Uint(0), .Int(0), .F64(0), .Counter(0),
            .Timestamp(Date(timeIntervalSince1970: 0)), .Boolean(false), .Unknown(typeCode: 0, data: Data()), .Null,
        ]
        for (i, lhs) in values.enumerated() {
            for (j, rhs) in values.enumerated() {
                XCTAssertEqual(lhs == rhs, i == j, "\(lhs) vs \(rhs)")
            }
        }
        XCTAssertEqual(Set(values).count, values.count)
    }

    func testSetOfValuesFindsANaNItContains() throws {
        let doc = Document()
        try doc.put(obj: .ROOT, key: "value", value: .F64(.nan))
        let values = try doc.getAll(obj: .ROOT, key: "value")
        XCTAssertTrue(values.contains(.Scalar(.F64(.nan))))
    }

    func testDocumentHoldingNaNHasContentsEquivalentToItsFork() throws {
        let doc = Document()
        try doc.put(obj: .ROOT, key: "value", value: .F64(.nan))
        XCTAssertTrue(doc.equivalentContents(doc.fork()))
        XCTAssertTrue(try doc.equivalentContents(Document(doc.save())))
    }
}
