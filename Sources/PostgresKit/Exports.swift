#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import AsyncKit
@_documentation(visibility: internal) @_exported import PostgresNIO
@_documentation(visibility: internal) @_exported import SQLKit
@_documentation(visibility: internal) @_exported import struct Foundation.URL

#else

@_exported import AsyncKit
@_exported import PostgresNIO
@_exported import SQLKit
@_exported import struct Foundation.URL

#endif
