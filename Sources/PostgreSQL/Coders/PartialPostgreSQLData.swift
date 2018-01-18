/// Reference wrapper for `PostgreSQLData` being mutated
/// by the PostgreSQL data coders.
final class PartialPostgreSQLData {
    /// The partial data.
    var data: PostgreSQLData

    /// Creates a new `PartialPostgreSQLData`.
    init(data: PostgreSQLData) {
        self.data = data
    }

    /// Sets the `PostgreSQLData` at supplied coding path.
    func set(_ data: PostgreSQLData, at path: [CodingKey]) throws {
        set(&self.data, to: data, at: path)
    }

    /// Returns the value, if one at from the given path.
    func get(at path: [CodingKey]) -> PostgreSQLData? {
        var child = data

        for seg in path {
            guard let c = child.dictionary?[seg.stringValue] else {
                return nil
            }
            child = c
        }

        return child
    }

    /// Gets a value at the supplied path or throws a decoding error.
    func requireGet(at path: [CodingKey]) throws -> PostgreSQLData {
        switch get(at: path) {
        case .some(let w): return w
        case .none: throw DecodingError.valueNotFound(Bool.self, .init(codingPath: path, debugDescription: ""))
        }
    }

    /// Sets the mutable `PostgreSQLData` to supplied data at coding path.
    private func set(_ context: inout PostgreSQLData, to value: PostgreSQLData, at path: [CodingKey]) {
        guard path.count >= 1 else {
            context = value
            return
        }

        let end = path[0]

        var child: PostgreSQLData?
        switch path.count {
        case 1:
            child = value
        case 2...:
            if let index = end.intValue {
                let array = context.array ?? []
                if array.count > index {
                    child = array[index]
                } else {
                    child = PostgreSQLData.array([])
                }
                set(&child!, to: value, at: Array(path[1...]))
            } else {
                child = context.dictionary?[end.stringValue] ?? PostgreSQLData.dictionary([:])
                set(&child!, to: value, at: Array(path[1...]))
            }
        default: break
        }

        if let index = end.intValue {
            if case .array(var arr) = context {
                if arr.count > index {
                    arr[index] = child ?? .null
                } else {
                    arr.append(child ?? .null)
                }
                context = .array(arr)
            } else if let child = child {
                context = .array([child])
            }
        } else {
            if case .dictionary(var dict) = context {
                dict[end.stringValue] = child
                context = .dictionary(dict)
            } else if let child = child {
                context = .dictionary([
                    end.stringValue: child
                ])
            }
        }
    }
}
