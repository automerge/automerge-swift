import Automerge
import XCTest

final class AutomergeDocTests: XCTestCase {
    var doc: Document!

    override func setUp() {
        doc = Document()
    }

    func testNoteEncodeDecode() throws {
        struct Note: Codable, Equatable {
            let created: Date
            var notes: String
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)

        let sample = Note(
            created: Date(),
            notes: "An example string to show encoding."
        )
        try automergeEncoder.encode(sample)
        print(sample)
        // Note(created: 2023-08-01 23:28:38 +0000, notes: "An example string to show encoding.")

        let automergeDecoder = AutomergeDecoder(doc: doc)

        let decodedStruct = try automergeDecoder.decode(Note.self)
        print(decodedStruct)

        XCTAssertEqual(decodedStruct.notes, sample.notes)
    }

    func testUsingCounter() throws {
        struct Ballot: Codable, Equatable {
            var votes: Counter
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)

        let initial = Ballot(
            votes: Counter(0)
        )
        try automergeEncoder.encode(initial)

        // Fork the document
        let pollingPlace1 = doc.fork()
        let place1decoder = AutomergeDecoder(doc: pollingPlace1)
        // Decode the type from the document
        var place1 = try place1decoder.decode(Ballot.self)
        // Update the value
        place1.votes.value = 3
        // Encode the value back into the document to persist it.
        let place1encoder = AutomergeEncoder(doc: pollingPlace1)
        try place1encoder.encode(place1)

        // Repeat with a second Automerge document, forked and updated separately.
        let pollingPlace2 = doc.fork()
        let place2decoder = AutomergeDecoder(doc: pollingPlace2)
        var place2 = try place2decoder.decode(Ballot.self)
        place2.votes.value = -1
        let place2encoder = AutomergeEncoder(doc: pollingPlace2)
        try place2encoder.encode(place2)

        // Merge the data from the document representing place2 into place1 to
        // get a combined count

        try pollingPlace1.merge(other: pollingPlace2)
        let updatedPlace1 = try place1decoder.decode(Ballot.self)
        print(updatedPlace1.votes.value)
        // 2

        XCTAssertEqual(updatedPlace1.votes.value, 2)
    }

    func testQuickStartDocs() throws {
        struct ColorList: Codable {
            var colors: [String]
        }

        // Creating a Document

        let doc = Document()
        let encoder = AutomergeEncoder(doc: doc)

        var myColors = ColorList(colors: ["blue", "red"])
        try encoder.encode(myColors)

        // Making Changes

        myColors.colors.append("green")
        try encoder.encode(myColors)

        print(myColors.colors)
        // ["blue", "red", "green"]

        XCTAssertEqual(myColors.colors, ["blue", "red", "green"])

        // Saving the Document

        let bytesToStore = doc.save()

        // Forking and Merging Documents

        let doc2 = try Document(bytesToStore)

        let doc3 = doc.fork()

        let doc2decoder = AutomergeDecoder(doc: doc2)
        var copyOfColorList = try doc2decoder.decode(ColorList.self)

        copyOfColorList.colors.removeFirst()
        let doc2encoder = AutomergeEncoder(doc: doc2)
        try doc2encoder.encode(copyOfColorList)

        try doc.merge(other: doc2)
        let decoder = AutomergeDecoder(doc: doc)
        myColors = try decoder.decode(ColorList.self)

        print(myColors.colors)
        // ["red", "green"]

        XCTAssertEqual(myColors.colors, ["red", "green"])

        XCTAssertNotNil(bytesToStore)
        XCTAssertNotNil(doc3)
    }
}
