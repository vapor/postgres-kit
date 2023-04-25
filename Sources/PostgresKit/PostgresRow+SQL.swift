import PostgresNIO
import Foundation
import SQLKit

extension PostgresRow {
    @available(*, deprecated, message: "Use `.sql(jsonDecoder:)` instead.")
    public func sql(decoder: PostgresDataDecoder) -> SQLRow {
        _PostgresSQLRow(row: self.makeRandomAccess(), decodingContext: decoder.underlyingContext)
    }
    
    public func sql<D: PostgresJSONDecoder>(jsonDecoder: D) -> SQLRow {
        _PostgresSQLRow(row: self.makeRandomAccess(), decodingContext: .init(jsonDecoder: jsonDecoder))
    }
    
    public func sql() -> SQLRow {
        _PostgresSQLRow(row: self.makeRandomAccess(), decodingContext: .default)
    }
}

// MARK: Private

private struct _PostgresSQLRow<D: PostgresJSONDecoder>: SQLRow {
    let randomAccessView: PostgresRandomAccessRow
    let decodingContext: PostgresDecodingContext<D>

    enum _Error: Error {
        case missingColumn(String)
    }
    
    init(row: PostgresRandomAccessRow, decodingContext: PostgresDecodingContext<D>) {
        self.randomAccessView = row
        self.decodingContext = decodingContext
    }

    var allColumns: [String] { self.randomAccessView.map { $0.columnName } }
    func contains(column: String) -> Bool { self.randomAccessView.contains(column) }

    func decodeNil(column: String) throws -> Bool {
        !self.randomAccessView.contains(column) || self.randomAccessView[column].bytes == nil
    }

    func decode<D>(column: String, as type: D.Type) throws -> D where D : Decodable {
        guard self.randomAccessView.contains(column) else {
            throw _Error.missingColumn(column)
        }
        
        return try PostgresDataTranslation.decode(D.self, from: self.randomAccessView[column], in: self.decodingContext)
    }
}
