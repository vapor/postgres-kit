import Bits

/*
 Describe (F)
 Byte1('D')
 Identifies the message as a Describe command.

 Int32
 Length of message contents in bytes, including self.

 Byte1
 'S' to describe a prepared statement; or 'P' to describe a portal.

 String
 The name of the prepared statement or portal to describe (an empty string selects the unnamed prepared statement or portal).

 */

/// Identifies the message as a Describe command.
struct PostgreSQLDescribeRequest: Encodable {
    /// 'S' to describe a prepared statement; or 'P' to describe a portal.
    let type: PostgreSQLDescribeType

    /// The name of the prepared statement or portal to describe
    /// (an empty string selects the unnamed prepared statement or portal).
    var name: String
}

enum PostgreSQLDescribeType: Byte, Encodable {
    case statement = 0x53 // S
    case portal = 0x50 // P
}
