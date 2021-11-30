//
//  VendorExtendable.swift
//  
//
//  Created by Mathew Polzin on 10/6/19.
//

/// A `VendorExtendable` type is a type that supports arbitrary
/// additions as long as those additions are keyed by strings starting
/// with "x-" (e.g. "x-customThing").
public protocol VendorExtendable {
    typealias VendorExtensions = [String: AnyCodable]

    /// Dictionary of vendor extensions.
    ///
    /// These should be of the form:
    /// `[ "x-extensionKey": <anything>]`
    /// where the values are anything codable.
    var vendorExtensions: VendorExtensions { get }
}

internal protocol ExtendableCodingKey: CodingKey, Equatable {
    /// An array of all keys that are not vendor extensions.
    static var allBuiltinKeys: [Self] { get }

    /// Given a String key, return the vendor extension key representation
    /// of that key.
    ///
    /// For example, an `enum` type might represent `"x-extensionExample"`
    /// as `.extended("x-extensionExample")`
    ///
    static func extendedKey(for value: String) -> Self
}

extension ExtendableCodingKey {
    /// Returns a builtin key if possible, but assumes any other
    /// key is an extended key.
    internal static func key(for value: String) -> Self {
        return Self(stringValue: value) ?? .extendedKey(for: value)
    }

    internal init?(intValue: Int) {
        return nil
    }

    internal var intValue: Int? {
        return nil
    }
}

internal protocol CodableVendorExtendable: VendorExtendable {
    associatedtype CodingKeys: ExtendableCodingKey
}

internal enum VendorExtensionDecodingError: Swift.Error, CustomStringConvertible {
    case selfIsArrayNotDict
    case foundNonStringKeys

    var description: String {
        switch self {
        case .selfIsArrayNotDict:
            return "Tried to get vendor extensions on a list. Vendor extensions are necessarily keyed and therefore can only be retrieved from hashes."
        case .foundNonStringKeys:
            return "Vendor extension keys must be string values."
        }
    }
}

extension CodableVendorExtendable {

    internal static func extensions(from decoder: Decoder) throws -> VendorExtensions {
        return [:] // This gives us x2.5 speedup
    }

    internal func encodeExtensions<T: KeyedEncodingContainerProtocol>(to container: inout T) throws where T.Key == Self.CodingKeys {
        for (key, value) in vendorExtensions {
            let xKey = key.starts(with: "x-") ? key : "x-\(key)"
            try container.encode(value, forKey: .extendedKey(for: xKey))
        }
    }
}
