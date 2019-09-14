/// IPv4 or IPv6 network address
public struct PostgreSQLCidr: PostgreSQLInetCidrInterface {
    /// IP version
    public var version: PostgreSQLIpVersion
    
    /// The IP address values
    public var bytes: [UInt8]
    
    /// The IP address netmask
    public var netmask: UInt8
    
    /// The data format
    public static var format: PostgreSQLDataFormat { return .cidr }
    
    /// Create a new struct from the info
    public init(version: PostgreSQLIpVersion, bytes: [UInt8], netmask: UInt8? = nil) throws {
        // check bytes
        if bytes.count > version.maxLength ||
            (version == .ipv6 && bytes.count % 2 != 0) {
            throw PostgreSQLError(identifier: "cidr", reason: "Invalid length: \(bytes.count)")
        }
        
        // check netmask
        let netmask = netmask ?? version.maxBits
        if netmask > version.maxBits ||
            netmask % (version.bytesPerAddress * 8) != 0 {
            throw PostgreSQLError(identifier: "cidr", reason: "Invalid netmask: \(netmask)")
        }
        
        // cidr can't have any non zero bytes beyond the netmask
        let validBytes = Int(netmask / 8)
        if (validBytes < bytes.count ? Array(bytes.suffix(from: validBytes)).map{ Int($0) }.reduce(0,+) : 0) > 0 {
            throw PostgreSQLError(identifier: "cidr", reason: "Values set beyond mask")
        }
        
        // for cidr, zero pad if it is less than the bytes
        var bytes = bytes
        while bytes.count < validBytes { bytes.append(0) }
        
        // store attributes
        self.version = version
        self.bytes = bytes
        self.netmask = netmask
    }
}

/// IPv4 or IPv6 host address
public struct PostgreSQLInet: PostgreSQLInetCidrInterface {
    /// IP version
    public var version: PostgreSQLIpVersion
    
    /// The IP address values
    public var bytes: [UInt8]
    
    /// The IP address netmask
    public var netmask: UInt8
    
    /// The data format
    public static var format: PostgreSQLDataFormat { return .inet }
    
    /// Create a new struct from the info
    public init(version: PostgreSQLIpVersion, bytes: [UInt8], netmask: UInt8? = nil) throws {
        // check netmask
        let netmask = netmask ?? version.maxBits
        if netmask > version.maxBits ||
            netmask % (version.bytesPerAddress * 8) != 0 {
            throw PostgreSQLError(identifier: "inet", reason: "Invalid netmask: \(netmask)")
        }
        
        // check bytes
        if bytes.count > version.maxLength ||
            bytes.count < Int(netmask/8) ||
            (version == .ipv6 && bytes.count % 2 != 0) {
            throw PostgreSQLError(identifier: "inet", reason: "Invalid length: \(bytes.count)")
        }

        // store attributes
        self.version = version
        self.bytes = bytes
        self.netmask = netmask
    }
}

/// IP Version Type
/// https://doxygen.postgresql.org/utils_2inet_8h.html
public enum PostgreSQLIpVersion: UInt8, Codable {
    case ipv4 = 2
    case ipv6 = 3
    
    /// family
    var family: UInt8 {
        return self.rawValue
    }
    
    /// max number of bits
    var maxBits: UInt8 {
        switch self {
        case .ipv4: return 32
        case .ipv6: return 128
        }
    }
    
    /// max length in bytes
    var maxLength: UInt8 {
        switch self {
        case .ipv4: return 4
        case .ipv6: return 16
        }
    }
    
    /// size of each address portion
    var bytesPerAddress: UInt8 {
        switch self {
        case .ipv4: return 1
        case .ipv6: return 2
        }
    }
}

/// Protocol for enabling reuse between 'inet' and 'cidr'
public protocol PostgreSQLInetCidrInterface: CustomStringConvertible, Codable, Equatable, PostgreSQLDataConvertible {
    /// IP version
    var version: PostgreSQLIpVersion { get }
    
    /// The IP address values
    var bytes: [UInt8] { get }
    
    /// The IP address netmask
    var netmask: UInt8 { get }
    
    /// The data format ('inet' or 'cidr')
    static var format: PostgreSQLDataFormat { get }

    /// Contructor
    init(version: PostgreSQLIpVersion, bytes: [UInt8], netmask: UInt8?) throws
}

/// PostgreSQLInetCidrInterface implementation
extension PostgreSQLInetCidrInterface {
    /// Returns true if this is cidr
    var format: PostgreSQLDataFormat { return type(of: self).format }
    
    /// Returns true is this is cidr
    var isCidr: Bool { return self.format == .cidr }
    
    /// Returns the valid bytes based on the submask
    var validBytes: Int { return self.isCidr ? Int(self.netmask / 8) : (Int(self.version.maxBits) / 8) }
    
    /// See `CustomStringConvertible`.
    public var description: String {
        if self.version == .ipv4 {
            return "\(self.bytes.prefix(self.validBytes).map{ "\($0)" }.joined(separator: "."))" +
                (self.netmask != self.version.maxBits ? "/\(netmask)" : "")
        }
        else {
            var sections = [String]()
            for i in 0..<(min(self.validBytes, self.bytes.count)/2) {
                let chunk = (UInt16(self.bytes[2*i]) << 8) + UInt16(self.bytes[2*i+1])
                sections.append(String(format:"%x", chunk))
            }
            
            return "\(sections.joined(separator: ":"))" +
                (self.validBytes < (self.version.maxBits / 8) ? "::" : "") +
                (self.netmask != self.version.maxBits ? "/\(netmask)" : "")
        }
    }

    /// Create a new struct from a string
    public init(string: String) throws {
        // get netmask
        let parts = string.split(separator: "/")
        let netmask = parts.count == 2 ? UInt8(parts[1]) : nil
        let address = String(parts[0])
        
        // IPV6
        if string.contains(":") {
            // extract the bytes
            var bytes = [UInt8]()
            for chunk in address.replacingOccurrences(of: "::", with: "").split(separator: ":") {
                let chunk16 = UInt16(chunk, radix: 16) ?? 0
                bytes.append(UInt8(chunk16 >> 8))
                bytes.append(UInt8(truncatingIfNeeded: chunk16))
            }
            
            try self.init(version: .ipv6, bytes: bytes, netmask: netmask)
        }
        // IPV4
        else {
            // get the addresses
            let addressParts: [String]
            if address.contains(".") { addressParts = address.split(separator: ".").map{ String($0) } }
            else if address.contains("-") { addressParts = address.split(separator: "-").map{ String($0) } }
            else { addressParts = [address] }
            
            try self.init(version: .ipv4, bytes: addressParts.map{ UInt8($0) ?? 0 }, netmask: netmask)
        }
    }
    
    /// Create a new `Inet/Cidr' from data
    init(data: Data) throws {
        // data to bytes
        var bytes = [UInt8]()
        bytes.append(contentsOf: data)
        
        // check bytes
        if bytes.count < 4 {
            throw PostgreSQLError(identifier: "inet/cidr", reason: "Invalid payload: \(data)")
        }
        
        // get attibutes
        guard let version = PostgreSQLIpVersion(rawValue: bytes[0]) else {
            throw PostgreSQLError(identifier: "inet/cidr", reason: "Invalid version: \(bytes[0])")
        }
        let netmask = bytes[1]
        let _ = bytes[2] // ignore is_cidr
        let length = bytes[3]
        
        // check legnth
        if 4+length != bytes.count {
            throw PostgreSQLError(identifier: "inet/cidr", reason: "Invalid payload length: \(length)")
        }
        
        // initialize
        try self.init(version: version, bytes: Array(bytes.suffix(from: 4)), netmask: netmask)
    }
    
    /// Serializes the inet/cidr
    /// https://github.com/postgres/postgres/blob/master/src/backend/utils/adt/network.c
    var toData: Data {
        return Data(bytes: ([self.version.family, self.netmask, (self.isCidr ? 1 : 0), UInt8(self.bytes.count)]+self.bytes))
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
            return try Self(data: value)
        case .null: throw PostgreSQLError.decode(self, from: data)
        }
    }
    
    /// See `PostgreSQLDataConvertible`.
    public func convertToPostgreSQLData() throws -> PostgreSQLData {
        return PostgreSQLData(self.format, binary: self.toData)
    }
}
