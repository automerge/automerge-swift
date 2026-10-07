@testable import Automerge
import XCTest

private func blockValue(_ type: String) -> [String: AutomergeValue] {
    ["type": .scalar(.String(type)), "parents": .array([]), "attrs": .dict([:])]
}

/// Asserts that an expression throws the document error for the wrong object type.
private func assertThrowsWrongObjectType<T>(
    _ expression: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertThrowsError(try expression(), file: file, line: line) { error in
        guard let docError = error as? DocError, case .WrongObjectType = docError.inner else {
            return XCTFail("Expected WrongObjectType, got \(error)", file: file, line: line)
        }
    }
}

class BlocksTestCase: XCTestCase {
    let paragraph = blockValue("paragraph")

    func testSplitBlockInsertsAMarker() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🐻🐻🐻bbbccc")
        let block = try doc.splitBlock(obj: text, index: 6)
        try doc.put(obj: block, key: "type", value: .String("li"))

        XCTAssertEqual(try doc.text(obj: text), "🐻🐻🐻bbb\u{FFFC}ccc")
        XCTAssertEqual(try doc.spans(obj: text), [
            .text("🐻🐻🐻bbb", marks: [:]),
            .block(["type": .scalar(.String("li"))]),
            .text("ccc", marks: [:]),
        ])
    }

    func testSplitBlockWithContents() throws {
        // Matches "can split a block" in automerge-wasm's blocks tests.
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "list", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🐻🐻🐻bbbccc")
        try doc.splitBlock(obj: text, index: 6, block: [
            "type": .scalar(.String("li")),
            "parents": .array([.scalar(.String("ul"))]),
            "attrs": .dict(["kind": .scalar(.String("todo")), "caption": .text("A caption")]),
        ])

        let expected: [String: AutomergeValue] = [
            "type": .scalar(.String("li")),
            "parents": .array([.scalar(.String("ul"))]),
            "attrs": .dict(["kind": .scalar(.String("todo")), "caption": .text("A caption")]),
        ]
        XCTAssertEqual(try doc.spans(obj: text), [
            .text("🐻🐻🐻bbb", marks: [:]),
            .block(expected),
            .text("ccc", marks: [:]),
        ])
        XCTAssertEqual(try doc.block(obj: text, index: 6), expected)

        // Text within a block is an Automerge text object, which can be edited in place.
        guard case let .Object(block, .Map) = try doc.values(obj: text)[6],
              case let .Object(attrs, .Map) = try doc.get(obj: block, key: "attrs"),
              case let .Object(caption, .Text) = try doc.get(obj: attrs, key: "caption")
        else {
            return XCTFail("Expected a caption text object in the block's attrs")
        }
        try doc.spliceText(obj: caption, start: 9, delete: 0, value: ", edited")
        XCTAssertEqual(try doc.text(obj: caption), "A caption, edited")
    }

    func testBlockReturnsNilForText() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "abc")
        XCTAssertNil(try doc.block(obj: text, index: 1))
    }

    func testJoinBlock() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🐻🐻🐻bbbccc")
        try doc.splitBlock(obj: text, index: 6, block: paragraph)
        try doc.joinBlock(obj: text, index: 6)
        XCTAssertEqual(try doc.text(obj: text), "🐻🐻🐻bbbccc")
        XCTAssertEqual(try doc.spans(obj: text), [.text("🐻🐻🐻bbbccc", marks: [:])])
    }

    func testJoinAndUpdateBlockRejectCharacters() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "abc")
        assertThrowsWrongObjectType(try doc.joinBlock(obj: text, index: 1))
        assertThrowsWrongObjectType(try doc.updateBlock(obj: text, index: 1, block: paragraph))
        XCTAssertEqual(try doc.text(obj: text), "abc")
    }

    func testBlockMethodsRejectObjectsOtherThanText() throws {
        let doc = Document()
        let list = try doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        try doc.insert(obj: list, index: 0, value: .String("a"))
        assertThrowsWrongObjectType(try doc.splitBlock(obj: list, index: 0))
        assertThrowsWrongObjectType(try doc.spans(obj: list))
        assertThrowsWrongObjectType(try doc.block(obj: list, index: 0))
    }

    func testUpdateBlock() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.splitBlock(obj: text, index: 0, block: paragraph)
        try doc.spliceText(obj: text, start: 1, delete: 0, value: "Title")
        let heading: [String: AutomergeValue] = [
            "type": .scalar(.String("heading")),
            "parents": .array([]),
            "attrs": .dict(["level": .scalar(.Int(1))]),
        ]
        try doc.updateBlock(obj: text, index: 0, block: heading)
        XCTAssertEqual(try doc.spans(obj: text), [.block(heading), .text("Title", marks: [:])])
    }

    func testSpansSplitTextWhereMarksChange() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.splitBlock(obj: text, index: 0, block: paragraph)
        try doc.spliceText(obj: text, start: 1, delete: 0, value: "Hello world")
        try doc.mark(obj: text, start: 4, end: 9, expand: .after, name: "bold", value: .Boolean(true))
        // Splitting inside the mark leaves it covering the text on both sides of the new marker.
        try doc.splitBlock(obj: text, index: 6, block: paragraph)

        XCTAssertEqual(try doc.spans(obj: text), [
            .block(paragraph),
            .text("Hel", marks: [:]),
            .text("lo", marks: ["bold": .Boolean(true)]),
            .block(paragraph),
            .text(" wo", marks: ["bold": .Boolean(true)]),
            .text("rld", marks: [:]),
        ])
    }

    func testSpansAndBlockAtHeads() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.splitBlock(obj: text, index: 0, block: paragraph)
        try doc.spliceText(obj: text, start: 1, delete: 0, value: "first")
        let heads = doc.heads()

        let block = try doc.splitBlock(obj: text, index: 6)
        try doc.put(obj: block, key: "type", value: .String("heading"))
        try doc.joinBlock(obj: text, index: 0)

        XCTAssertEqual(
            try doc.spans(obj: text),
            [.text("first", marks: [:]), .block(["type": .scalar(.String("heading"))])]
        )
        XCTAssertEqual(try doc.spansAt(obj: text, heads: heads), [.block(paragraph), .text("first", marks: [:])])
        XCTAssertNil(try doc.block(obj: text, index: 0))
        XCTAssertEqual(try doc.blockAt(obj: text, index: 0, heads: heads), paragraph)
    }

    func testPositionsFollowTheTextEncoding() throws {
        let doc = Document(textEncoding: .utf16)
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🐻bbb")
        // In UTF-16 code units the bear is two positions, so "bbb" starts at 2.
        try doc.splitBlock(obj: text, index: 2, block: paragraph)
        XCTAssertEqual(
            try doc.spans(obj: text),
            [.text("🐻", marks: [:]), .block(paragraph), .text("bbb", marks: [:])]
        )
        XCTAssertEqual(try doc.block(obj: text, index: 2), paragraph)
        try doc.joinBlock(obj: text, index: 2)
        XCTAssertEqual(try doc.text(obj: text), "🐻bbb")
    }

    func testConcurrentSplitAndJoinConverge() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.splitBlock(obj: text, index: 0, block: paragraph)
        try doc.spliceText(obj: text, start: 1, delete: 0, value: "Hello")
        try doc.splitBlock(obj: text, index: 6, block: paragraph)
        try doc.spliceText(obj: text, start: 7, delete: 0, value: "world")
        let fork = doc.fork()

        try doc.splitBlock(obj: text, index: 4, block: paragraph)
        try fork.joinBlock(obj: text, index: 6)
        try doc.merge(other: fork)
        try fork.merge(other: doc)

        let expected: [Span] = [
            .block(paragraph), .text("Hel", marks: [:]),
            .block(paragraph), .text("loworld", marks: [:]),
        ]
        XCTAssertEqual(try doc.spans(obj: text), expected)
        XCTAssertEqual(try fork.spans(obj: text), expected)
    }

    func testConcurrentUpdateBlockKeepsBothMarkers() throws {
        // updateBlock replaces the marker, as in Automerge's JavaScript library, so two concurrent updates leave
        // two markers. Writing to the block's map in place merges instead.
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.splitBlock(obj: text, index: 0, block: paragraph)
        try doc.spliceText(obj: text, start: 1, delete: 0, value: "Title")
        let fork = doc.fork()

        try doc.updateBlock(obj: text, index: 0, block: blockValue("heading"))
        try fork.updateBlock(obj: text, index: 0, block: blockValue("quote"))
        try doc.merge(other: fork)

        let spans = try doc.spans(obj: text)
        XCTAssertEqual(spans.filter { if case .block = $0 { true } else { false } }.count, 2)
        XCTAssertEqual(spans.last, .text("Title", marks: [:]))
    }

    func testRemoteBlockArrivesAsAnObjectInsertPatch() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "ab")
        let fork = doc.fork()
        try fork.splitBlock(obj: text, index: 1, block: ["type": .scalar(.String("paragraph"))])

        let patches = try doc.mergeWithPatches(other: fork)
        XCTAssertTrue(patches.contains {
            if case let .Insert(_, index, values) = $0.action, index == 1, case .Object(_, .Map) = values.first {
                return true
            }
            return false
        })
        XCTAssertEqual(try doc.spans(obj: text), try fork.spans(obj: text))
    }
}
