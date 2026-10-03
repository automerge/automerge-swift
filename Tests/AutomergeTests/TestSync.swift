import Automerge
import XCTest

class SyncTests: XCTestCase {
    func testSyncTwoDocs() {
        let doc1 = Document()
        trackForMemoryLeak(instance: doc1)
        let syncState1 = SyncState()

        let doc2 = Document()
        trackForMemoryLeak(instance: doc2)
        let syncState2 = SyncState()

        try! doc1.put(obj: ObjId.ROOT, key: "key1", value: .String("value1"))
        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))

        sync(doc1, syncState1, doc2, syncState2)

        for doc in [doc1, doc2] {
            XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key1")!, .Scalar(.String("value1")))
            XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key2")!, .Scalar(.String("value2")))
        }

        XCTAssertNotNil(syncState1.theirHeads)
    }

    func testEncodedSyncStateResumesSync() throws {
        let doc1 = Document()
        let doc2 = Document()
        let syncState1 = SyncState()
        try doc1.put(obj: ObjId.ROOT, key: "key1", value: .String("value1"))
        sync(doc1, syncState1, doc2, SyncState())

        // Persist doc1's side of the connection, then reconnect with the restored state.
        let restored = try SyncState(bytes: syncState1.encode())
        try doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))
        sync(doc1, restored, doc2, SyncState())

        XCTAssertEqual(doc1.heads(), doc2.heads())
        XCTAssertEqual(try doc1.get(obj: ObjId.ROOT, key: "key2"), .Scalar(.String("value2")))
    }

    func testSyncStateFromInvalidBytesThrows() {
        for bytes in [Data(), Data([1, 2, 3, 4]), Data(repeating: 0xFF, count: 64)] {
            XCTAssertThrowsError(try SyncState(bytes: bytes), "bytes: \(Array(bytes))") { error in
                XCTAssertTrue(error is DecodeSyncStateError, "expected DecodeSyncStateError, got \(error)")
            }
        }
    }

    func testReceivingInvalidSyncMessageThrowsAndLeavesDocumentUnchanged() throws {
        let sender = Document()
        try sender.put(obj: ObjId.ROOT, key: "key", value: .String("value"))
        let validMessage = try XCTUnwrap(sender.generateSyncMessage(state: SyncState()))

        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "existing", value: .Int(1))
        let headsBefore = doc.heads()

        let invalidMessages = [
            Data(),
            Data([0x42, 1, 2, 3]),
            validMessage.prefix(validMessage.count / 2),
        ]
        for message in invalidMessages {
            XCTAssertThrowsError(
                try doc.receiveSyncMessage(state: SyncState(), message: message),
                "message: \(Array(message))"
            ) { error in
                XCTAssertTrue(error is ReceiveSyncError, "expected ReceiveSyncError, got \(error)")
            }
            XCTAssertThrowsError(try doc.receiveSyncMessageWithPatches(state: SyncState(), message: message)) { error in
                XCTAssertTrue(error is ReceiveSyncError, "expected ReceiveSyncError, got \(error)")
            }
        }

        XCTAssertEqual(doc.heads(), headsBefore)
        try doc.put(obj: ObjId.ROOT, key: "after", value: .Int(2))
        XCTAssertEqual(doc.keys(obj: ObjId.ROOT), ["after", "existing"])
    }

    func testSyncConvergesAfterDroppedFirstMessageAndReset() throws {
        let doc1 = Document()
        let doc2 = Document()
        let syncState1 = SyncState()
        let syncState2 = SyncState()
        try doc1.put(obj: ObjId.ROOT, key: "key1", value: .Int(1))
        try doc2.put(obj: ObjId.ROOT, key: "key2", value: .Int(2))

        // Generate a message and lose it, as if the connection dropped mid-sync.
        XCTAssertNotNil(doc1.generateSyncMessage(state: syncState1))
        syncState1.reset()
        syncState2.reset()

        sync(doc1, syncState1, doc2, syncState2)

        XCTAssertEqual(doc1.heads(), doc2.heads())
        XCTAssertEqual(doc1.keys(obj: ObjId.ROOT), ["key1", "key2"])
        XCTAssertEqual(doc2.keys(obj: ObjId.ROOT), ["key1", "key2"])
    }

    /// Whether delivering `message` to `receiver` would change its document.
    ///
    /// Checked by delivering to a fork of the receiver with a copy of its sync state, so the real receiver
    /// and its state are untouched.
    func messageCarriesChanges(_ message: Data, to receiver: Document, state: SyncState) throws -> Bool {
        let scratch = receiver.fork()
        try scratch.receiveSyncMessage(state: SyncState(bytes: state.encode()), message: message)
        return scratch.heads() != receiver.heads()
    }

    func testDuplicatedChangeCarryingMessageAppliesOnce() throws {
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "count", value: .Counter(0))
        let list = try doc1.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let doc2 = Document()
        let syncState1 = SyncState()
        let syncState2 = SyncState()
        sync(doc1, syncState1, doc2, syncState2)

        try doc1.increment(obj: ObjId.ROOT, key: "count", by: 5)
        try doc1.insert(obj: list, index: 0, value: .String("item"))

        // Deliver the message that carries the new changes twice.
        var duplicated = false
        for _ in 0 ..< 10 where !duplicated {
            if let message = doc1.generateSyncMessage(state: syncState1) {
                let carriesChanges = try messageCarriesChanges(message, to: doc2, state: syncState2)
                try doc2.receiveSyncMessage(state: syncState2, message: message)
                if carriesChanges {
                    try doc2.receiveSyncMessage(state: syncState2, message: message)
                    duplicated = true
                }
            }
            if let reply = doc2.generateSyncMessage(state: syncState2) {
                try doc1.receiveSyncMessage(state: syncState1, message: reply)
            }
        }
        XCTAssertTrue(duplicated, "no message from doc1 carried the new changes")

        sync(doc1, syncState1, doc2, syncState2)

        XCTAssertEqual(doc2.heads(), doc1.heads())
        XCTAssertEqual(try doc2.get(obj: ObjId.ROOT, key: "count"), .Scalar(.Counter(5)))
        XCTAssertEqual(doc2.length(obj: list), 1)
    }

    func testSyncRecoversFromChangeCarryingMessageDroppedMidSession() throws {
        let doc1 = Document()
        let doc2 = Document()
        let syncState1 = SyncState()
        let syncState2 = SyncState()
        try doc1.put(obj: ObjId.ROOT, key: "shared", value: .Int(0))
        sync(doc1, syncState1, doc2, syncState2)

        try doc1.put(obj: ObjId.ROOT, key: "fromDoc1", value: .Int(1))
        try doc2.put(obj: ObjId.ROOT, key: "fromDoc2", value: .Int(2))

        // Continue the established session, losing the first message that carries doc1's new change.
        var dropped = false
        for _ in 0 ..< 10 where !dropped {
            if let message = doc1.generateSyncMessage(state: syncState1) {
                if try messageCarriesChanges(message, to: doc2, state: syncState2) {
                    dropped = true
                } else {
                    try doc2.receiveSyncMessage(state: syncState2, message: message)
                }
            }
            if !dropped, let reply = doc2.generateSyncMessage(state: syncState2) {
                try doc1.receiveSyncMessage(state: syncState1, message: reply)
            }
        }
        XCTAssertTrue(dropped, "no message from doc1 carried the new change")
        XCTAssertFalse(doc2.keys(obj: ObjId.ROOT).contains("fromDoc1"))

        syncState1.reset()
        syncState2.reset()
        sync(doc1, syncState1, doc2, syncState2)

        XCTAssertEqual(doc1.heads(), doc2.heads())
        XCTAssertEqual(doc1.keys(obj: ObjId.ROOT), ["fromDoc1", "fromDoc2", "shared"])
        XCTAssertEqual(doc2.keys(obj: ObjId.ROOT), ["fromDoc1", "fromDoc2", "shared"])
    }

    func testSyncStateRemainsUsableAfterMalformedMessage() throws {
        let doc1 = Document()
        let doc2 = Document()
        let syncState1 = SyncState()
        let syncState2 = SyncState()
        try doc1.put(obj: ObjId.ROOT, key: "shared", value: .Int(0))
        sync(doc1, syncState1, doc2, syncState2)

        // Malformed messages arrive on the established session. The truncated message comes from an
        // unrelated sync state, so the real session doesn't think anything is in flight.
        let validMessage = try XCTUnwrap(doc1.generateSyncMessage(state: SyncState()))
        for message in [Data([0x42, 1, 2, 3]), validMessage.prefix(validMessage.count / 2)] {
            XCTAssertThrowsError(try doc2.receiveSyncMessage(state: syncState2, message: message)) { error in
                XCTAssertTrue(error is ReceiveSyncError, "expected ReceiveSyncError, got \(error)")
            }
        }

        // The same sync states carry on with new edits from both sides.
        try doc1.put(obj: ObjId.ROOT, key: "fromDoc1", value: .Int(1))
        try doc2.put(obj: ObjId.ROOT, key: "fromDoc2", value: .Int(2))
        sync(doc1, syncState1, doc2, syncState2)

        XCTAssertEqual(doc1.heads(), doc2.heads())
        XCTAssertEqual(doc1.keys(obj: ObjId.ROOT), ["fromDoc1", "fromDoc2", "shared"])
        XCTAssertEqual(doc2.keys(obj: ObjId.ROOT), ["fromDoc1", "fromDoc2", "shared"])
    }

    func testThreePeersConverge() throws {
        let peers = [Document(), Document(), Document()]
        for (index, peer) in peers.enumerated() {
            try peer.put(obj: ObjId.ROOT, key: "peer\(index)", value: .Int(Int64(index)))
        }

        // Peers 0 and 2 only ever talk to peer 1.
        let states = (0 ..< 4).map { _ in SyncState() }
        for _ in 0 ..< 3 {
            sync(peers[0], states[0], peers[1], states[1])
            sync(peers[1], states[2], peers[2], states[3])
        }

        let expectedKeys = ["peer0", "peer1", "peer2"]
        for peer in peers {
            XCTAssertEqual(peer.keys(obj: ObjId.ROOT), expectedKeys)
            XCTAssertEqual(peer.heads(), peers[0].heads())
        }
    }

    func testSyncLargeConcurrentHistories() throws {
        let doc1 = Document()
        let doc2 = doc1.fork()
        let list1 = try doc1.putObject(obj: ObjId.ROOT, key: "list1", ty: .List)
        let list2 = try doc2.putObject(obj: ObjId.ROOT, key: "list2", ty: .List)
        for i in 0 ..< 500 {
            try doc1.insert(obj: list1, index: UInt64(i), value: .Int(Int64(i)))
            try doc2.insert(obj: list2, index: UInt64(i), value: .Int(Int64(i)))
            // Commit periodically so the histories contain many separate changes.
            if i % 10 == 0 {
                doc1.commitWith()
                doc2.commitWith()
            }
        }

        sync(doc1, SyncState(), doc2, SyncState())

        XCTAssertEqual(doc1.heads(), doc2.heads())
        XCTAssertEqual(doc1.length(obj: list2), 500)
        XCTAssertEqual(doc2.length(obj: list1), 500)
    }
}

/// Exchanges sync messages between two documents until neither has anything left to send.
///
/// Fails the calling test, rather than looping forever, if the documents don't settle within `maxRounds`.
func sync(
    _ doc1: Document,
    _ sync1: SyncState,
    _ doc2: Document,
    _ sync2: SyncState,
    maxRounds: Int = 100,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        for _ in 0 ..< maxRounds {
            var quiet = true

            if let msg = doc1.generateSyncMessage(state: sync1) {
                quiet = false
                try doc2.receiveSyncMessage(state: sync2, message: msg)
            }

            if let msg = doc2.generateSyncMessage(state: sync2) {
                quiet = false
                try doc1.receiveSyncMessage(state: sync1, message: msg)
            }

            if quiet {
                return
            }
        }
        XCTFail("documents did not finish syncing within \(maxRounds) rounds", file: file, line: line)
    } catch {
        XCTFail("sync failed: \(error)", file: file, line: line)
    }
}
