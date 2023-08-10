//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 09/08/2023.
//

import Foundation

public struct Cursor: Equatable, Hashable, Sendable {
    internal var bytes: [UInt8]
}

extension Cursor: CustomStringConvertible {
    public var description: String {
        bytes.map { Swift.String(format: "%02hhx", $0) }.joined().uppercased()
    }
}
