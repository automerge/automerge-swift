import Automerge
import XCTest

final class CounterEncodeDecodeTests: XCTestCase {
    var doc: Document!

    override func setUp() {
        doc = Document()
    }

    struct Ballot: Codable, Equatable {
        var vote: Counter
    }

    func testCounterMergeWithEncodeDecode() throws {
        let encoder = AutomergeEncoder(doc: doc)
        let decoder = AutomergeDecoder(doc: doc)

        let baselineBallot = Ballot(vote: Counter(0))

        try encoder.encode(baselineBallot)
        let emptyDecodeCheck = try decoder.decode(Ballot.self)
        XCTAssertNotNil(emptyDecodeCheck)
        XCTAssertEqual(emptyDecodeCheck.vote.value, 0)

        // update BallotA/docA with +3
        let docA = doc.fork()
        let encoderA = AutomergeEncoder(doc: docA)
        let decoderA = AutomergeDecoder(doc: docA)
        var ballotA = try decoderA.decode(Ballot.self)
        ballotA.vote.value += 3
        try encoderA.encode(ballotA)

        // update BallotB/docB with -1
        let docB = doc.fork()
        let encoderB = AutomergeEncoder(doc: docB)
        let decoderB = AutomergeDecoder(doc: docB)
        var ballotB = try decoderB.decode(Ballot.self)
        ballotB.vote.value -= 1
        try encoderB.encode(ballotB)

        // remerge in both directions
        try docA.merge(other: docB)
        try docB.merge(other: docA)

        // reload the ballots from the docs
        ballotA = try decoderA.decode(Ballot.self)
        ballotB = try decoderB.decode(Ballot.self)
        XCTAssertEqual(ballotA.vote.value, 2)
        XCTAssertEqual(ballotB.vote.value, 2)
    }
}
