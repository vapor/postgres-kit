extension ChannelPipeline {
    /// Adds PostgreSQL message encoder and decoder to the channel pipeline.
    ///
    /// - parameters:
    ///     - first: If `true`, adds the handlers first. Defaults to `false`.
    /// - returns: A future signaling completion.
    public func addPostgreSQLClientHandlers(first: Bool = false) -> Future<Void> {
        return addHandlers([PostgreSQLMessageEncoder(), PostgreSQLMessageDecoder()], first: first)
    }
}
