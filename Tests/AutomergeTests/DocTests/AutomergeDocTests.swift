import Automerge
import XCTest

extension String {
    @inlinable func automergeIndexPosition(index: String.Index) -> UInt64? {
        guard let unicodeScalarIndex: String.UnicodeScalarView.Index = index.samePosition(in: unicodeScalars) else {
            return nil
        }
        let intPositionInUnicodeScalar = unicodeScalars.distance(
            from: unicodeScalars.startIndex,
            to: unicodeScalarIndex
        )
        return UInt64(intPositionInUnicodeScalar)
    }
}

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
        let place1 = try place1decoder.decode(Ballot.self)
        // Update the value
        place1.votes.value = 3
        // Encode the value back into the document to persist it.
        let place1encoder = AutomergeEncoder(doc: pollingPlace1)
        try place1encoder.encode(place1)

        // try pollingPlace1.walk()

        // Repeat with a second Automerge document, forked and updated separately.
        let pollingPlace2 = doc.fork()
        let place2decoder = AutomergeDecoder(doc: pollingPlace2)
        let place2 = try place2decoder.decode(Ballot.self)
        place2.votes.value = -1
        let place2encoder = AutomergeEncoder(doc: pollingPlace2)
        try place2encoder.encode(place2)

        // try pollingPlace2.walk()

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

    func testPathElementAnyCodingKey() throws {
        let doc = Document()
        let exampleList = try doc.putObject(obj: ObjId.ROOT, key: "example", ty: .List)
        let listItem = try doc.insertObject(obj: exampleList, index: 0, ty: .Map)

        let path = try doc.path(obj: listItem)
        let stringFromPath = path.stringPath()

        // print(stringFromPath)
        // .example.[0]

        XCTAssertEqual(stringFromPath, ".example.[0]")
    }

    @inlinable func convertToUTF8Index(someString: String, index: String.Index) -> Int? {
        guard let utf8index: String.UTF8View.Index = index.samePosition(in: someString.utf8) else {
            return nil
        }
        let intPositionInUTF8 = someString.utf8.distance(from: someString.utf8.startIndex, to: utf8index)
        return intPositionInUTF8
    }

    @inlinable func convertToUnicodeScalarsIndex(someString: String, index: String.Index) -> Int? {
        guard let unicodeScalarIndex: String.UnicodeScalarView.Index = index
            .samePosition(in: someString.unicodeScalars)
        else {
            return nil
        }
        let intPositionInUnicodeScalar = someString.unicodeScalars.distance(
            from: someString.unicodeScalars.startIndex,
            to: unicodeScalarIndex
        )
        return intPositionInUnicodeScalar
    }

    func testTextIndexConversionsExample() throws {
        let doc = Document()
        let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "🇬🇧👨‍👨‍👧‍👦😀")

        let start = UInt64("🇬🇧".unicodeScalars.count)
        XCTAssertEqual(start, 2)

        let delete = Int64("👨‍👨‍👧‍👦".unicodeScalars.count)
        XCTAssertEqual(delete, 7)

        let end = UInt64("😀".unicodeScalars.count)
        XCTAssertEqual(end, 1)

        let stringFromAutomerge = try XCTUnwrap(doc.text(obj: textId))
        XCTAssertEqual(stringFromAutomerge.unicodeScalars.count, 10)

        let utf8IndexLength = stringFromAutomerge.utf8.distance(
            from: stringFromAutomerge.utf8.startIndex,
            to: stringFromAutomerge.utf8.endIndex
        )
        print("UTF8 index length: \(utf8IndexLength)")

        let unicodeScalarIndexLength = stringFromAutomerge.unicodeScalars.distance(
            from: stringFromAutomerge.unicodeScalars.startIndex,
            to: stringFromAutomerge.unicodeScalars.endIndex
        )
        print("unicodeScalar index length: \(unicodeScalarIndexLength)")

        let index🇬🇧: String.Index = try XCTUnwrap(stringFromAutomerge.firstIndex(of: "🇬🇧"))
        let index👨‍👨‍👧‍👦: String.Index = try XCTUnwrap(stringFromAutomerge.firstIndex(of: "👨‍👨‍👧‍👦"))
        let index😀: String.Index = try XCTUnwrap(stringFromAutomerge.firstIndex(of: "😀"))
        print("utf8 index position of 🇬🇧: \(convertToUTF8Index(someString: stringFromAutomerge, index: index🇬🇧))") // 0
        print("utf8 index position of 👨‍👨‍👧‍👦: \(convertToUTF8Index(someString: stringFromAutomerge, index: index👨‍👨‍👧‍👦))") // 8
        print("utf8 index position of 😀: \(convertToUTF8Index(someString: stringFromAutomerge, index: index😀))") // 33

        print(
            "unicodescalar index position of 🇬🇧: \(convertToUnicodeScalarsIndex(someString: stringFromAutomerge, index: index🇬🇧))"
        ) // 0
        print(
            "unicodescalar index position of 👨‍👨‍👧‍👦: \(convertToUnicodeScalarsIndex(someString: stringFromAutomerge, index: index👨‍👨‍👧‍👦))"
        ) // 2
        print(
            "unicodescalar index position of 😀: \(convertToUnicodeScalarsIndex(someString: stringFromAutomerge, index: index😀))"
        ) // 9

        try doc.spliceText(obj: textId, start: start, delete: delete) // delete "👨‍👨‍👧‍👦"

        let stringLength = doc.length(obj: textId)
        XCTAssertEqual(stringLength, start + end)

        let text = try doc.text(obj: textId)
        XCTAssertEqual(text, "🇬🇧😀")
    }
}
