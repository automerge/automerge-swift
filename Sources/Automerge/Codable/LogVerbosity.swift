/// A type that indicates the amount of logging to be exposed from the Automerge library.
public enum LogVerbosity: Int, Comparable, Equatable {
    // DEVNOTE(heckj): Using an internal/custom enumeration to indicate
    // these values because this library supports back to macOS 11.15
    // when Unified Logging wasn't available on related platforms.
    //
    // In addition, I'm using this as a comparator before logging anything
    // because the default os.Logger implementation made available to
    // both AppKit and UIKit doesn't include any filtering capability by level.

    /// Determines whether the first verbosity level is less verbose than the second.
    /// - Parameters:
    ///   - lhs: The first verbosity level to compare.
    ///   - rhs: The second verbosity level to compare.
    /// - Returns: Returns true if the first verbosity level is less than the second.
    public static func < (lhs: LogVerbosity, rhs: LogVerbosity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // loosely matching the levels from https://datatracker.ietf.org/doc/html/rfc5424
    /// Log errors only.
    case errorOnly = 3
    /// Logs include debugging and informational detail.
    case debug = 6
    /// Logs include all debugging and additional tracing details.
    case tracing = 8
}
