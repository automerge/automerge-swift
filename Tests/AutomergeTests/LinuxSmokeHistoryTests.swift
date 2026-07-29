#if os(Linux)
import Automerge
import XCTest

final class LinuxSmokeHistoryTests: XCTestCase {
    func testCreatePersistForkMergeHistoryAndSync() throws {
        let original = Document()
        try original.put(obj: ObjId.ROOT, key: "seed", value: .String("created"))

        let persisted = original.save()
        let left = try Document(persisted)
        XCTAssertEqual(
            try left.get(obj: ObjId.ROOT, key: "seed"),
            .Scalar(.String("created"))
        )
        XCTAssertEqual(left.getHistory().count, 1)

        let right = left.fork()
        XCTAssertEqual(left.heads(), right.heads())

        try left.put(obj: ObjId.ROOT, key: "left", value: .String("offline-left"))
        try right.put(obj: ObjId.ROOT, key: "right", value: .String("offline-right"))
        XCTAssertNotEqual(left.heads(), right.heads())

        try left.merge(other: right)
        XCTAssertEqual(
            try left.get(obj: ObjId.ROOT, key: "left"),
            .Scalar(.String("offline-left"))
        )
        XCTAssertEqual(
            try left.get(obj: ObjId.ROOT, key: "right"),
            .Scalar(.String("offline-right"))
        )
        XCTAssertGreaterThanOrEqual(left.getHistory().count, 3)

        let peer = Document()
        let leftSyncState = SyncState()
        let peerSyncState = SyncState()
        try exchangeMessages(left, leftSyncState, peer, peerSyncState)

        XCTAssertEqual(left.heads(), peer.heads())
        XCTAssertEqual(
            try peer.get(obj: ObjId.ROOT, key: "right"),
            .Scalar(.String("offline-right"))
        )

        try peer.put(obj: ObjId.ROOT, key: "peer", value: .String("synced-back"))
        try exchangeMessages(left, leftSyncState, peer, peerSyncState)
        XCTAssertEqual(
            try left.get(obj: ObjId.ROOT, key: "peer"),
            .Scalar(.String("synced-back"))
        )
        XCTAssertEqual(left.heads(), peer.heads())
    }

    private func exchangeMessages(
        _ first: Document,
        _ firstState: SyncState,
        _ second: Document,
        _ secondState: SyncState
    ) throws {
        var converged = false

        for _ in 0 ..< 100 {
            var exchangedMessage = false

            if let message = first.generateSyncMessage(state: firstState) {
                try second.receiveSyncMessage(state: secondState, message: message)
                exchangedMessage = true
            }

            if let message = second.generateSyncMessage(state: secondState) {
                try first.receiveSyncMessage(state: firstState, message: message)
                exchangedMessage = true
            }

            if !exchangedMessage {
                converged = true
                break
            }
        }

        XCTAssertTrue(converged, "sync did not converge within 100 message exchanges")
    }
}
#endif
