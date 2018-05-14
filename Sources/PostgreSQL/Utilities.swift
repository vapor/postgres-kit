import Bits
import Foundation
import NIO
import Debugging



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
            let first = popFirst()
            assert(first != nil)
        }
    }

    internal mutating func skip<T>(sizeOf: T.Type) {
        skip(MemoryLayout<T>.size)
    }

    /// Casts data to a supplied type.
    internal mutating func extract<T>(_ type: T.Type = T.self) -> T {
        assert(MemoryLayout<T>.size <= count, "Insufficient data to exctract: \(T.self)")
        defer { skip(sizeOf: T.self) }
        return withUnsafeBytes { (pointer: UnsafePointer<T>) -> T in
            return pointer.pointee
        }
    }

    internal mutating func extract(count: Int) -> Data {
        assert(self.count >= count, "Insufficient data to extract bytes.")
        defer { skip(count) }
        return withUnsafeBytes({ (pointer: UnsafePointer<UInt8>) -> Data in
            let buffer = UnsafeBufferPointer(start: pointer, count: count)
            return Data(buffer)
        })
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
