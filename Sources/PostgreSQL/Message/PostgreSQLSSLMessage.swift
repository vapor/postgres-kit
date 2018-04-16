/// First message sent from the frontend during startup if SSL is enabled.
struct PostgreSQLSSLMessage: Encodable {
    /// The SSL request code. The value is chosen to contain 1234 in the most significant 16 bits,
    /// and 5679 in the least significant 16 bits.
    let sslRequestCode: Int32 = 80877103

    /// See Encodable.encode
    func encode(to encoder: Encoder) throws {
        var single = encoder.singleValueContainer()
        try single.encode(sslRequestCode)
    }
}
