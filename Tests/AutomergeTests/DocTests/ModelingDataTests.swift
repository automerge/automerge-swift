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
        
        let pollingPlace1 = doc.fork()
        let place1decoder = AutomergeDecoder(doc: pollingPlace1)
        var place1 = try place1decoder.decode(Ballot.self)
        print(place1.votes.value)
        // 0
        place1.votes.value = 2
        
        
    }

}
