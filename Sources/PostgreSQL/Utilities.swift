import Bits
import Foundation

extension Data {
    public var hexDebug: String {
        return "0x" + map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

extension UnsafeBufferPointer {
    public var unsafeBaseAddress: UnsafePointer<Element> {
        guard let baseAddress = self.baseAddress else {
            fatalError("Unexpected nil baseAddress for \(self)")
        }
        return baseAddress
    }
}

extension UnsafeRawBufferPointer {
    public var unsafeBaseAddress: UnsafeRawPointer {
        guard let baseAddress = self.baseAddress else {
            fatalError("Unexpected nil baseAddress for \(self)")
        }
        return baseAddress
    }
}

extension Data {
    internal mutating func unsafePopFirst() -> Byte {
        guard let byte = popFirst() else {
            fatalError("Unexpected end of data")
        }
        return byte
    }

    internal mutating func skip(_ n: Int) {
        guard n < count else {
            self = Data()
            return
        }
        for _ in 0..<n {
            assert(popFirst() != nil)
        }
    }

    internal mutating func skip<T>(sizeOf: T.Type) {
        skip(MemoryLayout<T>.size)
    }

    /// Casts data to a supplied type.
    internal mutating func extract<T>(_ type: T.Type = T.self) -> T {
        assert(MemoryLayout<T>.size <= count, "Insufficient data to decode: \(T.self)")
        defer { skip(sizeOf: T.self) }
        return withUnsafeBytes { (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }
}


extension Data {
    /// Casts data to a supplied type.
    internal func unsafeCast<T>(to type: T.Type = T.self) -> T {
        return withUnsafeBytes { (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }

    
}
