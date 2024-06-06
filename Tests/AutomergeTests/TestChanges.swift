import Automerge
import XCTest

class ChangeSetTests: XCTestCase {
    func testHeadsForNewDoc() {
        let doc = Document()

        // verify new document has an empty set of changes
        let heads = doc.heads()
        XCTAssertTrue(heads.isEmpty)
    }

    func testIncrChangesForNewDoc() throws {
        let doc = Document()

        // verify new document has an empty set of changes
        let updates = try doc.encodeChangesSince(heads: Set<ChangeHash>())
        XCTAssertTrue(updates.isEmpty)
    }

    func testIncrementalLoadEmptySet() throws {
        let doc = Document()
        let bytes = doc.save()
        try doc.applyEncodedChanges(encoded: Data())

        let heads = doc.heads()
        XCTAssertTrue(heads.isEmpty)

        // verify no-op
        let data = doc.save()
        XCTAssertEqual(bytes, data)
        // print(data.hexEncodedString())
    }

    func testDifferenceToPreviousCommit() throws {
        let doc = Document()
        doc.difference(to: doc.heads())
        let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
        
        let before = doc.heads()
        try doc.spliceText(obj: textId, start: 5, delete: 0, value: " World 👨‍👩‍👧‍👦")

        let patches = doc.difference(to: before)
        let length = UInt64(" World 👨‍👩‍👧‍👦".unicodeScalars.count)
        XCTAssertEqual(patches.count, 1)
        XCTAssertEqual(patches.first?.action, .DeleteSeq(DeleteSeq(obj: textId, index: 5, length: length)))
    }

    func testDifferenceFromPreviousCommit() throws {
        let doc = Document()
        let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
        
        let before = doc.heads()
        try doc.spliceText(obj: textId, start: 5, delete: 0, value: " World 👨‍👩‍👧‍👦")

        let patches = doc.difference(from: before)
        XCTAssertEqual(patches.count, 1)
        XCTAssertEqual(patches.first?.action, .SpliceText(obj: textId, index: 5, value: " World 👨‍👩‍👧‍👦", marks: [:]))
    }

    func testDifferenceBetweenTwoCommitsInHistory() throws {
        let doc = Document()
        let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let before = doc.heads()
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
        try doc.spliceText(obj: textId, start: 5, delete: 0, value: " World 👨‍👩‍👧‍👦")
        let after = doc.heads()

        let patches = doc.difference(from: before, to: after)
        XCTAssertEqual(patches.count, 1)
        XCTAssertEqual(patches.first?.action, .SpliceText(obj: textId, index: 0, value: "Hello World 👨‍👩‍👧‍👦", marks: [:]))
    }

    func testDifferenceProperty_DifferenceBetweenCommitAndCurrent_DifferenceFromCommit_ResultsEquals() throws {
        let doc = Document()
        let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let before = doc.heads()
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
        try doc.spliceText(obj: textId, start: 5, delete: 0, value: " World 👨‍👩‍👧‍👦")

        let patches1 = doc.difference(from: before, to: doc.heads())
        let patches2 = doc.difference(from: before)
        XCTAssertEqual(patches1.count, 1)
        XCTAssertEqual(patches1, patches2)
    }
}
