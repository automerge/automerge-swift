@testable import Automerge
import XCTest

class ActorTests: XCTestCase {
    func testDefaultActorSize() {
        let doc1 = Document()
        XCTAssertEqual(doc1.actor.data.count, 16)
    }

    func testInvalidActorFromData() throws {
        // Actor ID which is too long (150 bytes)
        // Max size is 128 bytes
        XCTAssertNil(ActorId(data: Data(repeating: 0, count: 150)))
    }

    func testActorFromUUID() throws {
        // Actor ID from a UUID
        let uuidActor2 = UUID(uuidString: "06a2b97e-69c9-4036-a97f-d4167a2bb779")!
        let actor2 = ActorId(uuid: uuidActor2)
        XCTAssertNotNil(actor2)
        XCTAssertEqual(actor2.description, "06A2B97E69C94036A97FD4167A2BB779")
    }

    func testReadingAndWritingActorFromData() throws {
        struct Dog: Codable {
            var name: String
            var age: Int
        }

        // Valid 32-byte actor ID
        let actor1 = try XCTUnwrap(
            ActorId(data: Data(
                [
                    0x00,
                    0x01,
                    0x02,
                    0x03,
                    0x04,
                    0x05,
                    0x06,
                    0x07,
                    0x08,
                    0x09,
                    0x0A,
                    0x0B,
                    0x0C,
                    0x0D,
                    0x0E,
                    0x0F,
                    0x10,
                    0x11,
                    0x12,
                    0x13,
                    0x14,
                    0x15,
                    0x16,
                    0x17,
                    0x18,
                    0x19,
                    0x1A,
                    0x1B,
                    0x1C,
                    0x1D,
                    0x1E,
                    0x1F,
                ]
            ))
        )

        XCTAssertEqual(actor1.description, "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F")

        // Actor ID from a UUID
        let uuidActor2 = UUID(uuidString: "06a2b97e-69c9-4036-a97f-d4167a2bb779")!
        let actor2 = ActorId(uuid: uuidActor2)
        XCTAssertEqual(actor2.description, "06A2B97E69C94036A97FD4167A2BB779")

        // Create the document
        let doc = Document()
        let encoder = AutomergeEncoder(doc: doc)
        doc.actor = actor1

        // Make an initial change
        var myDog = Dog(name: "Fido", age: 1)
        try encoder.encode(myDog)
        _ = doc.save()

        // Change the actor and make another change
        doc.actor = actor2
        myDog.age = 2
        try encoder.encode(myDog)
        _ = doc.save()

        // Verify the changes
        let changes = doc.getHistory().map { doc.change(hash: $0) }
        XCTAssertEqual(changes.count, 2)
        XCTAssertEqual(changes[0]!.actorId, actor1)
        XCTAssertEqual(changes[1]!.actorId, actor2)
    }
}
