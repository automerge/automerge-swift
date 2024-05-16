@testable import Automerge
import XCTest

class BlocksTestCase: XCTestCase {
    func testSplitBlock() async throws {
        // replicating test from https://github.com/automerge/automerge/blob/main/rust/automerge-wasm/test/blocks.mts#L8
        // to verify interactions

        // although looking through it, the test at
        // https://github.com/automerge/automerge/blob/main/rust/automerge/tests/block_tests.rs#L11
        // would make a lot more sense...
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "example", ty: ObjType.Text)
        try doc.updateText(obj: text, value: "🐻🐻🐻bbbccc")
        let result = try doc.splitBlock(obj: text, index: 6)
        // try doc.walk()
    }

    /*
     it("can split a block", () => {
       const doc = create({ actor: "aabbcc" })
       const text = doc.putObject("_root", "list", "🐻🐻🐻bbbccc")
       doc.splitBlock(text, 6, { type: "li", parents: ["ul"], attrs: {kind: "todo" }});

     NOTE(heckj):
     ^^ JS API wraps two calls in Rust api- first splitting the block, second updating the block that was just split

       const spans = doc.spans("/list");
         console.log(JSON.stringify(spans))
       assert.deepStrictEqual(spans, [
         { type: "text", value: "🐻🐻🐻" },
         { type: 'block', value: { type: 'li', parents: ['ul'], attrs: {kind: "todo"} } },
         { type: 'text', value: 'bbbccc' }
       ])
     })

     */

    func testJoinBlock() async throws {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "example", ty: ObjType.Text)
        try doc.updateText(obj: text, value: "🐻🐻🐻bbbccc")
        let result = try doc.splitBlock(obj: text, index: 6)
        try doc.joinBlock(obj: text, index: 6)
    }
}
