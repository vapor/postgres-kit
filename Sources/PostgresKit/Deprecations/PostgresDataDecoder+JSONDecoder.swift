import class Foundation.JSONDecoder

extension PostgresDataDecoder {
    @available(*, deprecated, renamed: "json")
    public var jsonDecoder: JSONDecoder {
        return self.json as! JSONDecoder
    }
}
