import Automerge
import AutomergeUtilities
import XCTest

class UtilityTests: XCTestCase {
    func testIsEmpty() throws {
        let doc = Document()
        XCTAssertTrue(try doc.isEmpty())

        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        XCTAssertFalse(try doc.isEmpty())
    }

    func testVerySimpleWalkSchema() throws {
        let doc = Document()
        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let schema = try doc.schema()
        // print(schema.description)
        XCTAssertEqual(schema.description, "{[\"text\": T{}]}")
    }

    func testWalkSchema() throws {
        let doc = Document()
        let enc = AutomergeEncoder(doc: doc)
        try enc.encode(Samples.layered)

        let schema = try doc.schema()
        XCTAssertEqual(schema, .dict([
            "title": .scalar(.String(Samples.layered.title)),
            "notes": .array(Samples.layered.notes.map { note in
                var location: [String: AutomergeValue] = [
                    "latitude": .scalar(.F64(note.location.latitude)),
                    "longitude": .scalar(.F64(note.location.longitude)),
                ]
                // Optional properties that are nil aren't encoded.
                for (key, value) in [
                    ("altitude", note.location.altitude),
                    ("speed", note.location.speed),
                    ("heading", note.location.heading),
                ] {
                    if let value { location[key] = .scalar(.F64(value)) }
                }
                return .dict([
                    "timestamp": .scalar(.Timestamp(note.timestamp)),
                    "description": .scalar(.String(note.description)),
                    "location": .dict(location),
                    "ratings": .array(note.ratings.map { .scalar(.Int(Int64($0))) }),
                ])
            }),
        ]))
    }
}
