import PostgresNIO
import Foundation
import SQLKit

extension PostgresRow {
    @inlinable
    public func sql() -> some SQLRow {
        self.sql(decodingContext: .default)
    }
    
    public func sql(decodingContext: PostgresDecodingContext<some PostgresJSONDecoder>) -> some SQLRow {
        _PostgresSQLRow(randomAccessView: self.makeRandomAccess(), decodingContext: decodingContext)
    }
}

private struct _PostgresSQLRow<D: PostgresJSONDecoder> {
    let randomAccessView: PostgresRandomAccessRow
    let decodingContext: PostgresDecodingContext<D>

    enum _Error: Error {
        case missingColumn(String)
    }
}

extension _PostgresSQLRow: SQLRow {
    var allColumns: [String] {
        self.randomAccessView.map { $0.columnName }
    }

    func contains(column: String) -> Bool {
        self.randomAccessView.contains(column)
    }

    func decodeNil(column: String) throws -> Bool {
        !self.randomAccessView.contains(column) || self.randomAccessView[column].bytes == nil
    }

    func decode<T: Decodable>(column: String, as type: T.Type) throws -> T {
        guard self.randomAccessView.contains(column) else {
            throw _Error.missingColumn(column)
        }
        
        return try PostgresDataTranslation.decode(T.self, from: self.randomAccessView[column], in: self.decodingContext)
    }
}
