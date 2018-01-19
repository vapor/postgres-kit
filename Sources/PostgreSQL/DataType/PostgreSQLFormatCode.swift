/// The format code being used for the field.
/// Currently will be zero (text) or one (binary).
/// In a RowDescription returned from the statement variant of Describe,
/// the format code is not yet known and will always be zero.
public enum PostgreSQLFormatCode: Int16, Codable {
    case text = 0
    case binary = 1
}
