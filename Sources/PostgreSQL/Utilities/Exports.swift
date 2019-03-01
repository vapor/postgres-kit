@_exported import DatabaseKit
@_exported import SQL

extension PostgreSQLPoint {
    @available(*, deprecated, message: "This will be removed in the next major version")
    public func endiannessflipped() -> PostgreSQLPoint {
        return PostgreSQLPoint(
            x: self.x.endiannessflipped(),
            y: self.y.endiannessflipped()
        )
    }
}

private extension Double {
    func endiannessflipped() -> Double {
        return Data(Data.of(self).reversed()).as(Double.self, default: 0)
    }
}
