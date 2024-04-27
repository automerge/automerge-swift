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

        // second encode - no change, verify it's all still there
        let serialized = doc.save()

        let newDoc = try Document(serialized)
        let newDecoder = AutomergeDecoder(doc: newDoc)
        var secondEncodeCheck = try newDecoder.decode(NoteCollection.self)
        XCTAssertNotNil(secondEncodeCheck)
        XCTAssertEqual(secondEncodeCheck.notes.count, 2)
        XCTAssertEqual(secondEncodeCheck.notes[0].title, "one")
        XCTAssertEqual(secondEncodeCheck.notes[0].discussion.value, "hello world")
        XCTAssertTrue(secondEncodeCheck.notes[0].discussion.isBound)
        XCTAssertTrue(secondEncodeCheck.notes[1].discussion.isBound)

        secondEncodeCheck.notes[1].title = "fred"
        secondEncodeCheck.notes[1].discussion.value = "new info here"
        let newEncoder = AutomergeEncoder(doc: newDoc)
        try newEncoder.encode(secondEncodeCheck)

        let _ = try newDecoder.decode(NoteCollection.self)
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

        // second encode - no change, verify it's all still there
        try encoder.encode(collection)
        let secondEncodeCheck = try decoder.decode(RawNoteCollection.self)
        XCTAssertNotNil(secondEncodeCheck)
        XCTAssertEqual(secondEncodeCheck.notes.count, 2)
        XCTAssertEqual(secondEncodeCheck.notes[0].value, "hello world")
        XCTAssertTrue(secondEncodeCheck.notes[0].isBound)
        XCTAssertEqual(secondEncodeCheck.notes[1].value, "")
        XCTAssertTrue(secondEncodeCheck.notes[1].isBound)
    }

    func testBindOnEncodeList() throws {
        let encoder = AutomergeEncoder(doc: doc)

        var collection = RawNoteCollection(notes: [])
        collection.notes.append(AutomergeText("hello world"))
        collection.notes.append(AutomergeText(""))
        XCTAssertFalse(collection.notes[0].isBound)
        XCTAssertFalse(collection.notes[1].isBound)

        try encoder.encode(collection)
        XCTAssertTrue(collection.notes[0].isBound)
        XCTAssertTrue(collection.notes[1].isBound)
    }

    func testBindOnEncodeNested() throws {
        let encoder = AutomergeEncoder(doc: doc)

        var collection = NoteCollection(notes: [])
        let note1 = Note(title: "one", discussion: AutomergeText("hello world"))
        let note2 = Note(title: "", discussion: AutomergeText())
        collection.notes.append(note1)
        collection.notes.append(note2)
        XCTAssertFalse(note1.discussion.isBound)
        XCTAssertFalse(note2.discussion.isBound)

        try encoder.encode(collection)
        XCTAssertTrue(note1.discussion.isBound)
        XCTAssertTrue(note2.discussion.isBound)
    }

    func testBindOnEncodeDecodeDirect() throws {
        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let note = AutomergeText("something")
        XCTAssertFalse(note.isBound)

        try encoder.encode(note)
        XCTAssertTrue(note.isBound)

        let decodeCheck = try decoder.decode(AutomergeText.self)
        XCTAssertEqual(decodeCheck.value, "something")
        XCTAssertTrue(decodeCheck.isBound)

        try doc.walk()
    }
}
