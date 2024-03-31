import Automerge
import XCTest

final class AutomergeEncoderTests: XCTestCase {
    var doc: Document!
    var setupCache: [String: ObjId] = [:]

    override func setUp() {
        setupCache = [:]
        doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        setupCache["list"] = list

        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        setupCache["nestedMap"] = nestedMap

        try! doc.put(obj: nestedMap, key: "image", value: .Bytes(Data()))
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)
        setupCache["deeplyNestedText"] = deeplyNestedText
    }

    func testSimpleKeyEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let date: Date
            let data: Data
            let uuid: UUID
            let url: URL
            let notes: AutomergeText
        }
        let automergeEncoder = AutomergeEncoder(doc: doc)

        let dateFormatter = ISO8601DateFormatter()
        let earlyDate = dateFormatter.date(from: "1941-04-26T08:17:00Z")!

        let sample = SimpleStruct(
            name: "henry",
            duration: 3.14159,
            flag: true,
            count: 5,
            date: earlyDate,
            data: Data("hello".utf8),
            uuid: UUID(uuidString: "99CEBB16-1062-4F21-8837-CF18EC09DCD7")!,
            url: URL(string: "http://url.com")!,
            notes: AutomergeText("Something wicked this way comes.")
        )

        try automergeEncoder.encode(sample)

        if case let .Scalar(.String(a_name)) = try doc.get(obj: ObjId.ROOT, key: "name") {
            XCTAssertEqual(a_name, "henry")
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "name")))")
        }

        if case let .Scalar(.F64(duration_value)) = try doc.get(obj: ObjId.ROOT, key: "duration") {
            XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "duration")))")
        }

        if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: ObjId.ROOT, key: "flag") {
            XCTAssertEqual(boolean_value, true)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "flag")))")
        }

        if case let .Scalar(.Int(int_value)) = try doc.get(obj: ObjId.ROOT, key: "count") {
            XCTAssertEqual(int_value, 5)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "count")))")
        }

        if case let .Scalar(.Timestamp(timestamp_value)) = try doc.get(obj: ObjId.ROOT, key: "date") {
            XCTAssertEqual(timestamp_value, -905182980)
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "date")))")
        }

        // try debugPrint(doc.get(obj: ObjId.ROOT, key: "data") as Any)
        if case let .Scalar(.Bytes(data_value)) = try doc.get(obj: ObjId.ROOT, key: "data") {
            XCTAssertEqual(data_value, Data("hello".utf8))
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "data")))")
        }

        // debugPrint(try doc.get(obj: ObjId.ROOT, key: "uuid") as Any)
        if case let .Scalar(.String(uuid_string)) = try doc.get(obj: ObjId.ROOT, key: "uuid") {
            XCTAssertEqual(uuid_string, "99CEBB16-1062-4F21-8837-CF18EC09DCD7")
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "uuid")))")
        }

        if case let .Object(textNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes") {
            XCTAssertEqual(nodeType, .Text)
            XCTAssertEqual(try doc.text(obj: textNode), "Something wicked this way comes.")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }

        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "url"), .Scalar("http://url.com"))
        try debugPrint(doc.get(obj: ObjId.ROOT, key: "notes") as Any)
    }

    func testNestedKeyEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
            let url: URL
        }

        struct RootModel: Codable {
            let example: SimpleStruct
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)

        let sample = RootModel(
            example: SimpleStruct(
                name: "henry",
                duration: 3.14159,
                flag: true,
                count: 5,
                url: URL(string: "http://url.com")!)
        )

        try automergeEncoder.encode(sample)

        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "example") {
            XCTAssertEqual(container_type, ObjType.Map)

            if case let .Scalar(.String(a_name)) = try doc.get(obj: container_id, key: "name") {
                XCTAssertEqual(a_name, "henry")
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "name")))")
            }

            if case let .Scalar(.F64(duration_value)) = try doc.get(obj: container_id, key: "duration") {
                XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "duration")))")
            }

            if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: container_id, key: "flag") {
                XCTAssertEqual(boolean_value, true)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "flag")))")
            }

            if case let .Scalar(.Int(int_value)) = try doc.get(obj: container_id, key: "count") {
                XCTAssertEqual(int_value, 5)
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, key: "count")))")
            }
            XCTAssertEqual(try doc.get(obj: container_id, key: "url"), .Scalar("http://url.com"))
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "example")))")
        }
    }

    func testNestedListSingleValueEncode() throws {
        struct RootModel: Codable {
            let numbers: [Int]
        }

        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)
        let sample = RootModel(numbers: [1, 2, 3])

        try automergeEncoder.encode(sample)

        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "numbers") {
            XCTAssertEqual(container_type, ObjType.List)
            XCTAssertEqual(try doc.get(obj: container_id, index: 0), .Scalar(1))
            XCTAssertEqual(try doc.get(obj: container_id, index: 1), .Scalar(2))
            XCTAssertEqual(try doc.get(obj: container_id, index: 2), .Scalar(3))
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "example")))")
        }
    }

    func testNestedListEncode() throws {
        struct SimpleStruct: Codable {
            let name: String
            let duration: Double
            let flag: Bool
            let count: Int
        }

        struct RootModel: Codable {
            let example: [SimpleStruct]
        }
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        let sample = RootModel(example: [
            SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5),
            SimpleStruct(name: "jules", duration: 2.7182818, flag: false, count: 2),
        ])

        try automergeEncoder.encode(sample)

        if case let .Object(container_id, container_type) = try doc.get(obj: ObjId.ROOT, key: "example") {
            XCTAssertEqual(container_type, ObjType.List)

            if case let .Object(firstListItem, first_list_type) = try doc.get(obj: container_id, index: 0) {
                XCTAssertEqual(first_list_type, ObjType.Map)

                if case let .Scalar(.String(a_name)) = try doc.get(obj: firstListItem, key: "name") {
                    XCTAssertEqual(a_name, "henry")
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "name")))")
                }

                if case let .Scalar(.F64(duration_value)) = try doc.get(obj: firstListItem, key: "duration") {
                    XCTAssertEqual(duration_value, 3.14159, accuracy: 0.01)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "duration")))")
                }

                if case let .Scalar(.Boolean(boolean_value)) = try doc.get(obj: firstListItem, key: "flag") {
                    XCTAssertEqual(boolean_value, true)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "flag")))")
                }

                if case let .Scalar(.Int(int_value)) = try doc.get(obj: firstListItem, key: "count") {
                    XCTAssertEqual(int_value, 5)
                } else {
                    try XCTFail("Didn't find: \(String(describing: doc.get(obj: firstListItem, key: "count")))")
                }
            } else {
                try XCTFail("Didn't find: \(String(describing: doc.get(obj: container_id, index: 0)))")
            }
        } else {
            try XCTFail("Didn't find: \(String(describing: doc.get(obj: ObjId.ROOT, key: "example")))")
        }
    }

    func testLayeredEncode() throws {
        let sample = Samples.layered
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        try automergeEncoder.encode(sample)
    }

    func testTextUpdateWithEncoding_Object() throws {
        let doc = Document()
        struct TestModel: Codable {
            var notes: AutomergeText
        }
        var model = TestModel(notes: AutomergeText("Hello"))
        let automergeEncoder = AutomergeEncoder(doc: doc)

        try automergeEncoder.encode(model)

        if case let .Object(textNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes") {
            XCTAssertEqual(nodeType, .Text)
            XCTAssertEqual(try doc.text(obj: textNode), "Hello")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }

        model.notes = AutomergeText("Hello World!")
        try automergeEncoder.encode(model)

        if case let .Object(textNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes") {
            XCTAssertEqual(nodeType, .Text)
            XCTAssertEqual(try doc.text(obj: textNode), "Hello World!")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }

        model.notes = AutomergeText("Wassup World?")
        try automergeEncoder.encode(model)

        if case let .Object(textNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes") {
            XCTAssertEqual(nodeType, .Text)
            XCTAssertEqual(try doc.text(obj: textNode), "Wassup World?")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }
    }

    func testTextUpdateWithEncoding_List() throws {
        let doc = Document()
        struct TestModel: Codable {
            var notes: [AutomergeText]
        }
        var model = TestModel(notes: [AutomergeText("Hello")])
        let automergeEncoder = AutomergeEncoder(doc: doc)

        try automergeEncoder.encode(model)

        if case let .Object(listNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes"),
           case let .Object(textNode, .Text) = try doc.get(obj: listNode, index: 0)
        {
            XCTAssertEqual(nodeType, .List)
            XCTAssertEqual(try doc.text(obj: textNode), "Hello")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }

        model.notes = [AutomergeText("Hello World!")]
        try automergeEncoder.encode(model)

        if case let .Object(listNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes"),
           case let .Object(textNode, .Text) = try doc.get(obj: listNode, index: 0)
        {
            XCTAssertEqual(nodeType, .List)
            XCTAssertEqual(try doc.text(obj: textNode), "Hello World!")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }

        model.notes = [AutomergeText("Wassup World?")]
        try automergeEncoder.encode(model)

        if case let .Object(listNode, nodeType) = try doc.get(obj: ObjId.ROOT, key: "notes"),
           case let .Object(textNode, .Text) = try doc.get(obj: listNode, index: 0)
        {
            XCTAssertEqual(nodeType, .List)
            XCTAssertEqual(try doc.text(obj: textNode), "Wassup World?")
        } else {
            try XCTFail("Didn't find an object at \(String(describing: doc.get(obj: ObjId.ROOT, key: "notes")))")
        }
    }

    func testTextEncodingMismatch_object() throws {
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        struct InitialTestModel: Codable {
            var notes: String
        }
        struct UpdatedTestModel: Codable {
            var notes: AutomergeText
        }

        let model = InitialTestModel(notes: "Hello")
        try automergeEncoder.encode(model)
        let followupModel = UpdatedTestModel(notes: AutomergeText("Hello"))

        XCTAssertThrowsError(
            try automergeEncoder.encode(followupModel),
            "Expected mismatched schema to throw error"
        ) { error in
            print(error)
        }
    }

    func testTextEncodingMismatch_list() throws {
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        struct InitialTestModel: Codable {
            var notes: [String]
        }
        struct UpdatedTestModel: Codable {
            var notes: [AutomergeText]
        }

        let model = InitialTestModel(notes: ["Hello"])
        try automergeEncoder.encode(model)
        let followupModel = UpdatedTestModel(notes: [AutomergeText("Hello")])

        XCTAssertThrowsError(
            try automergeEncoder.encode(followupModel),
            "Expected mismatched schema to throw error"
        ) { error in
            print(error)
        }
    }

    func testOptionalTypeEncode() throws {
        let doc = Document()
        let automergeEncoder = AutomergeEncoder(doc: doc)

        struct TestModel: Codable {
            var notes: [String]
        }

        let model: TestModel? = TestModel(notes: ["Hello"])
        XCTAssertNoThrow(try automergeEncoder.encode(model))
    }
}
