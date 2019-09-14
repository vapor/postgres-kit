/// MAC (Media Access Control) address
public struct PostgreSQLMacaddr: PostgreSQLMacaddrInterface {
    /// The MAC address values
    public var bytes: [UInt8]
    
    /// The data format
    public static var format: PostgreSQLDataFormat { return .macaddr }
    
    /// Create a new `Macaddr` from bytes
    public init(bytes: [UInt8]) throws {
        if bytes.count != 6 {
            throw PostgreSQLError(identifier: "macaddr", reason: "Invalid length: \(bytes.count)")
        }
        
        self.bytes = bytes
    }
}

/// MAC (Media Access Control) address (EUI-64 format)
public struct PostgreSQLMacaddr8: PostgreSQLMacaddrInterface {
    /// The MAC address values
    public var bytes: [UInt8]
    
    /// The data format
    public static var format: PostgreSQLDataFormat { return .macaddr8 }
    
    /// Create a new `Macaddr` from bytes
    public init(bytes: [UInt8]) throws {
        if bytes.count != 8 {
            throw PostgreSQLError(identifier: "macaddr8", reason: "Invalid length: \(bytes.count)")
        }
        
        self.bytes = bytes
    }
}

/// Protocol for enabling reuse between 'macaddr' and 'macaddr8'
public protocol PostgreSQLMacaddrInterface: CustomStringConvertible, Codable, Equatable, PostgreSQLDataConvertible {
    /// The IP address values
    var bytes: [UInt8] { get }
    
    /// The data format ('macaddr' or 'macaddr8')
    static var format: PostgreSQLDataFormat { get }
    
    /// Default Constructor
    init(bytes: [UInt8]) throws
}

/// PostgreSQLMacaddrInterface implementation
extension PostgreSQLMacaddrInterface {
    /// Returns true if this is cidr
    var format: PostgreSQLDataFormat { return type(of: self).format }
    
    /// See `CustomStringConvertible`.
    public var description: String {
        return "\(self.bytes.map{ String(format:"%02x", $0) }.joined(separator: ":"))"
    }
    
    /// Create a new 'Macaddr' from a string
    public init(string: String) throws {
        // get the addresses
        let addressParts: [String]
        if string.contains(":") { addressParts = string.split(separator: ":").map{ String($0) } }
        else if string.contains("-") { addressParts = string.split(separator: "-").map{ String($0) } }
        else { throw PostgreSQLError(identifier: "macaddr", reason: "Unknown delimeter") }

        try self.init(bytes: addressParts.map{ UInt8($0, radix: 16) ?? 0 })
    }

    /// See `PostgreSQLDataConvertible`.
    public static func convertFromPostgreSQLData(_ data: PostgreSQLData) throws -> Self {
        guard case self.format = data.type else {
            throw PostgreSQLError.decode(self, from: data)
        }
        switch data.storage {
        case .text(let string):
            return try Self(string: string)
        case .binary(let value):
            var received = [UInt8]()
            received.append(contentsOf: value)
            
            return try Self(bytes: received)
        case .null: throw PostgreSQLError.decode(self, from: data)
        }
    }
    
    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(self.format, binary: Data(bytes: self.bytes))
    }
}
