import Foundation

extension Data {
    public var hexDebug: String {
        return "0x" + map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
