import Bits
import Foundation
import NIO
import Debugging

extension ByteBuffer {
    mutating func write(nullTerminated string: String) {
        write(string: string)
        write(integer: 0, as: Byte.self)
    }
    
    mutating func readEnum<E>(_ type: E.Type) -> E? where E: RawRepresentable, E.RawValue: FixedWidthInteger {
        guard let rawValue = readInteger(as: E.RawValue.self) else {
            return nil
        }
        return E.init(rawValue: rawValue)
    }
    
    mutating func readNullableData() -> Data? {
        guard let count: Int = readInteger(as: Int32.self).flatMap(numericCast) else {
            return nil
        }
        switch count {
        case -1:
            // As a special case, -1 indicates a NULL parameter value. No value bytes follow in the NULL case.
            return nil
        default: return readData(length: count)
        }
    }
    
    mutating func write(nullableData: Data?) {
        if let data = nullableData {
            // The length of the parameter value, in bytes (this count does not include itself). Can be zero.
            write(integer: numericCast(data.count), as: Int32.self)
            // The value of the parameter, in the format indicated by the associated format code. n is the above length.
            write(bytes: data)
        } else {
            // As a special case, -1 indicates a NULL parameter value. No value bytes follow in the NULL case.
            write(integer: -1, as: Int32.self)
        }
    }
    
    mutating func readArray<T>(_ type: T.Type, _ closure: (inout ByteBuffer) throws -> (T)) rethrows -> [T]? {
        guard let count: Int = readInteger(as: Int16.self).flatMap(numericCast) else {
            return nil
        }
        var array: [T] = []
        array.reserveCapacity(count)
        for _ in 0..<count {
            try array.append(closure(&self))
        }
        return array
    }
    
    
    mutating func write<T>(array: [T], closure: (inout ByteBuffer, T) -> ()) {
        write(integer: numericCast(array.count), as: Int16.self)
        for el in array {
            closure(&self, el)
        }
    }
    
    mutating func write<T>(array: [T]) where T: FixedWidthInteger {
        write(array: array) { buffer, el in
            buffer.write(integer: el)
        }
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
