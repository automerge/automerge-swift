@testable import Automerge
import XCTest

class MarksTestCase: XCTestCase {
    func testCrudMarks() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: ObjType.Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello marks")
        try! doc.mark(
            obj: text,
            start: 0,
            end: 5,
            expand: ExpandMark.none,
            name: "bold",
            value: true
        )
        let marks = try! doc.marks(obj: text)
        let expectedMarks = [
            Mark(start: 0, end: 5, name: "bold", value: .Scalar(true)),
        ]
        XCTAssertEqual(marks, expectedMarks)

        // save the heads to use later in marksAt
        let heads = doc.heads()

        // Now remove the mark
        try! doc.mark(obj: text, start: 0, end: 5, expand: ExpandMark.none, name: "bold", value: nil)
        let marksAfterDelete = try! doc.marks(obj: text)
        XCTAssertEqual(marksAfterDelete.count, 0)

        // Now check that marksAt still returns the marks
        let marksAt = try! doc.marksAt(obj: text, heads: heads)
        XCTAssertEqual(marksAt, expectedMarks)
    }

    func testMarkPatches() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: ObjType.Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello marks")

        // Make the marks on a fork so we can see the marks in patches when we merge
        let fork = doc.fork()
        try! fork.mark(
            obj: text,
            start: 0,
            end: 5,
            expand: ExpandMark.none,
            name: "bold",
            value: true
        )
        let patches = try! doc.mergeWithPatches(other: fork)
        let expectedMarks = [
            Mark(start: 0, end: 5, name: "bold", value: .Scalar(true)),
        ]
        XCTAssertEqual(patches, [Patch(
            action: .Marks(text, expectedMarks),
            path: [PathElement(obj: ObjId.ROOT, prop: .Key("text"))]
        )])

        // Now splice some text in the fork and make sure the splice patch contains the marks
        try! fork.spliceText(obj: text, start: 4, delete: 0, value: "oo")
        let patchesAfterSplice = try! doc.mergeWithPatches(other: fork)
        XCTAssertEqual(patchesAfterSplice, [Patch(
            action: .SpliceText(obj: text, index: 4, value: "oo", marks: ["bold": .Scalar(true)]),
            path: [PathElement(obj: ObjId.ROOT, prop: .Key("text"))]
        )])
    }
}
