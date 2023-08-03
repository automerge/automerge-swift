import Automerge
import XCTest

final class EncodeDecodeBugTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
    }

    struct Note: Codable, Equatable {
        var title: String
        var discussion: AutomergeText
    }

    // example struct that works both the keyed and unkeyed encoder/decoder
    struct NoteCollection: Codable, Equatable {
        var notes: [Note]
    }

    // example struct that works the unkeyed encoder/decoder
    struct RawNoteCollection: Codable, Equatable {
        var notes: [AutomergeText]
    }

    func testNestedTextEncodeDecode() throws {
        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        var collection = NoteCollection(notes: [])
        try encoder.encode(collection)
        let emptyDecodeCheck = try decoder.decode(NoteCollection.self)
        XCTAssertNotNil(emptyDecodeCheck)
        XCTAssertEqual(emptyDecodeCheck.notes.count, 0)

        let note1 = Note(title: "one", discussion: AutomergeText("hello world"))
        let note2 = Note(title: "", discussion: AutomergeText())
        collection.notes.append(note1)
        collection.notes.append(note2)
        XCTAssertFalse(note1.discussion.isBound)
        XCTAssertFalse(note2.discussion.isBound)

        try encoder.encode(collection)
        let collectionAddedDecodeCheck = try decoder.decode(NoteCollection.self)
        XCTAssertNotNil(collectionAddedDecodeCheck)
        XCTAssertEqual(collectionAddedDecodeCheck.notes.count, 2)
        XCTAssertEqual(collectionAddedDecodeCheck.notes[0].title, "one")
        XCTAssertEqual(collectionAddedDecodeCheck.notes[0].discussion.value, "hello world")
        XCTAssertTrue(collectionAddedDecodeCheck.notes[0].discussion.isBound)
        XCTAssertTrue(collectionAddedDecodeCheck.notes[1].discussion.isBound)
    }

    func testNestedRawTextEncodeDecode() throws {
        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        var collection = RawNoteCollection(notes: [])
        try encoder.encode(collection)
        let emptyDecodeCheck = try decoder.decode(NoteCollection.self)
        XCTAssertNotNil(emptyDecodeCheck)
        XCTAssertEqual(emptyDecodeCheck.notes.count, 0)

        collection.notes.append(AutomergeText("hello world"))
        collection.notes.append(AutomergeText(""))
        XCTAssertFalse(collection.notes[0].isBound)
        XCTAssertFalse(collection.notes[1].isBound)

        try encoder.encode(collection)
        let collectionAddedDecodeCheck = try decoder.decode(RawNoteCollection.self)
        XCTAssertNotNil(collectionAddedDecodeCheck)
        XCTAssertEqual(collectionAddedDecodeCheck.notes.count, 2)
        XCTAssertEqual(collectionAddedDecodeCheck.notes[0].value, "hello world")
        XCTAssertTrue(collectionAddedDecodeCheck.notes[0].isBound)
        XCTAssertEqual(collectionAddedDecodeCheck.notes[1].value, "")
        XCTAssertTrue(collectionAddedDecodeCheck.notes[1].isBound)
    }
}
