import Foundation
@testable import Automerge
import XCTest

class InteropTests: XCTestCase {
    
    #if os(macOS)
    // DEVNOTE(heckj): Bundle based approaches for finding fixture files
    // work reasonably well with regular targets, but fail (or more specifically,
    // don't work as the docs assert) with resources embedded in test targets.
    //
    // As an alternative, this function returns the path URL to the **source files**
    // directory, which means that any tests relying on this function will only function
    // when run directly on the machine compiling all this stuff - for example, your mac
    //
    // This doesn't following the best practices asserting by Apple re: using URLs
    // to reference file paths, it's at least functional, short, and relatively easy
    // to understand if something goes awry.
    func fixturesDirectory(path: String = #file) -> URL {
        let url = URL(fileURLWithPath: path)
        let testsDir = url.deletingLastPathComponent()
        return testsDir.appendingPathComponent("Fixtures")
    }
    
    func dataFrom(resource: String) throws -> Data? {
        let urlForResource = fixturesDirectory().appending(component: resource)
        let data = try Data(contentsOf: urlForResource)
        return data
    }

    func testFileLoad() throws {
        let data = try dataFrom(resource: "markdown.md")
        XCTAssertNotNil(data)
    }
    #endif
}
