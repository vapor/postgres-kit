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
    public mutating func unsafePopFirst() -> Byte {
        guard let byte = popFirst() else {
            fatalError("Unexpected end of data")
        }
        return byte
    }
}
