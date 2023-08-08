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

}
