import Foundation

public enum Samples {
    public static var layered = ExampleModel(title: "Samples", notes: generateSampleNotes())
}

public struct GeoLocation: Hashable, Codable {
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var speed: Double?
    var heading: Double?

    init(latitude: Double, longitude: Double, altitude: Double? = nil, speed: Double? = nil, heading: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.heading = heading
    }
}

public struct Note: Hashable, Codable {
    var timestamp: Date
    var description: String
    var location: GeoLocation
    var ratings: [Int]

    init(timestamp: Date, description: String, location: GeoLocation, ratings: [Int]) {
        self.timestamp = timestamp
        self.description = description
        self.location = location
        self.ratings = ratings
    }
}

public struct ExampleModel: Codable {
    var title: String
    var notes: [Note]

    init(title: String, notes: [Note]) {
        self.title = title
        self.notes = notes
    }
}

func generateSampleNotes() -> [Note] {
    var result: [Note] = []
    do {
        try result.append(Note(
            timestamp: Date("1941-04-26T08:17:00Z", strategy: .iso8601),
            description: "Burlington",
            location: GeoLocation(latitude: 40.8057015, longitude: -91.1704486),
            ratings: [2, 4]
        ))
        try result.append(Note(
            timestamp: Date("1967-05-22T03:23:00Z", strategy: .iso8601),
            description: "St. Louis",
            location: GeoLocation(latitude: 38.653253, longitude: -90.4082707),
            ratings: [1, 3, 4, 2]
        ))
        try result.append(Note(
            timestamp: Date("2023-05-24T19:14:11Z", strategy: .iso8601),
            description: "Seattle",
            location: GeoLocation(latitude: 47.6131419, longitude: -122.5068714, altitude: 112),
            ratings: [4, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("2023-06-05T17:00:00Z", strategy: .iso8601),
            description: "WWDC",
            location: GeoLocation(latitude: 37.334648, longitude: -122.0115469, altitude: 50),
            ratings: [1, 2, 3, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("1941-04-26T08:17:00Z", strategy: .iso8601),
            description: "Burlington",
            location: GeoLocation(latitude: 40.8057015, longitude: -91.1704486),
            ratings: [2, 4]
        ))
        try result.append(Note(
            timestamp: Date("1967-05-22T03:23:00Z", strategy: .iso8601),
            description: "St. Louis",
            location: GeoLocation(latitude: 38.653253, longitude: -90.4082707),
            ratings: [1, 3, 4, 2]
        ))
        try result.append(Note(
            timestamp: Date("2023-05-24T19:14:11Z", strategy: .iso8601),
            description: "Seattle",
            location: GeoLocation(latitude: 47.6131419, longitude: -122.5068714, altitude: 112),
            ratings: [4, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("2023-06-05T17:00:00Z", strategy: .iso8601),
            description: "WWDC",
            location: GeoLocation(latitude: 37.334648, longitude: -122.0115469, altitude: 50),
            ratings: [1, 2, 3, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("1941-04-26T08:17:00Z", strategy: .iso8601),
            description: "Burlington",
            location: GeoLocation(latitude: 40.8057015, longitude: -91.1704486),
            ratings: [2, 4]
        ))
        try result.append(Note(
            timestamp: Date("1967-05-22T03:23:00Z", strategy: .iso8601),
            description: "St. Louis",
            location: GeoLocation(latitude: 38.653253, longitude: -90.4082707),
            ratings: [1, 3, 4, 2]
        ))
        try result.append(Note(
            timestamp: Date("2023-05-24T19:14:11Z", strategy: .iso8601),
            description: "Seattle",
            location: GeoLocation(latitude: 47.6131419, longitude: -122.5068714, altitude: 112),
            ratings: [4, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("2023-06-05T17:00:00Z", strategy: .iso8601),
            description: "WWDC",
            location: GeoLocation(latitude: 37.334648, longitude: -122.0115469, altitude: 50),
            ratings: [1, 2, 3, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("1941-04-26T08:17:00Z", strategy: .iso8601),
            description: "Burlington",
            location: GeoLocation(latitude: 40.8057015, longitude: -91.1704486),
            ratings: [2, 4]
        ))
        try result.append(Note(
            timestamp: Date("1967-05-22T03:23:00Z", strategy: .iso8601),
            description: "St. Louis",
            location: GeoLocation(latitude: 38.653253, longitude: -90.4082707),
            ratings: [1, 3, 4, 2]
        ))
        try result.append(Note(
            timestamp: Date("2023-05-24T19:14:11Z", strategy: .iso8601),
            description: "Seattle",
            location: GeoLocation(latitude: 47.6131419, longitude: -122.5068714, altitude: 112),
            ratings: [4, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("2023-06-05T17:00:00Z", strategy: .iso8601),
            description: "WWDC",
            location: GeoLocation(latitude: 37.334648, longitude: -122.0115469, altitude: 50),
            ratings: [1, 2, 3, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("1941-04-26T08:17:00Z", strategy: .iso8601),
            description: "Burlington",
            location: GeoLocation(latitude: 40.8057015, longitude: -91.1704486),
            ratings: [2, 4]
        ))
        try result.append(Note(
            timestamp: Date("1967-05-22T03:23:00Z", strategy: .iso8601),
            description: "St. Louis",
            location: GeoLocation(latitude: 38.653253, longitude: -90.4082707),
            ratings: [1, 3, 4, 2]
        ))
        try result.append(Note(
            timestamp: Date("2023-05-24T19:14:11Z", strategy: .iso8601),
            description: "Seattle",
            location: GeoLocation(latitude: 47.6131419, longitude: -122.5068714, altitude: 112),
            ratings: [4, 5, 4]
        ))
        try result.append(Note(
            timestamp: Date("2023-06-05T17:00:00Z", strategy: .iso8601),
            description: "WWDC",
            location: GeoLocation(latitude: 37.334648, longitude: -122.0115469, altitude: 50),
            ratings: [1, 2, 3, 5, 4]
        ))
    } catch {}
    return result
}
