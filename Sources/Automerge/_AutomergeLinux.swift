#if os(Linux)
// Error on compilation on Linux - The XCFramework, on which this package depends, could be made
// available for a variety of platforms, but there's not much of a smooth path to providing those
// binary assets for Swift on Linux.
//
// This file exists so that the compatibility indicators on Swift Package Index don't infer that
// this package is easily installed and used with Swift on Linux,
#error("This explicit error is to indicate that this package doesn't support Linux as it stands")
#endif
