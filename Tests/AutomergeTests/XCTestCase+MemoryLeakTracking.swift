import XCTest

extension XCTestCase {
    func trackForMemoryLeak(
        instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "potential memory leak on \(String(describing: instance))",
                file: file,
                line: line
            )
        }
    }
}
