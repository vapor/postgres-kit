# ``PostgresKit``

@Metadata {
    @TitleHeading(Package)
}

🐘 Non-blocking, event-driven Swift client for PostgreSQL.

### Usage

Use the SPM string to easily include the dependendency in your `Package.swift` file.

```swift
.package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0")
```

### Supported Platforms

PostgresKit supports the following platforms:

- Ubuntu 20.04+
- macOS 10.15+

## Overview

PostgresKit is an [SQLKit] driver for PostgreSQL clients. It supports building and serializing Postgres-dialect SQL queries. PostgresKit uses [PostgresNIO] to connect and communicate with the database server asynchronously. [AsyncKit] is used to provide connection pooling.

> Important: It is strongly recommended that users who leverage PostgresKit directly (e.g. absent the Fluent ORM layer) take advantage of PostgresNIO's [PostgresClient] API for connection management rather than relying upon the legacy AsyncKit API.

### Configuration

Database connection options and credentials are specified using a ``SQLPostgresConfiguration`` struct. 

```swift
import PostgresKit

let configuration = SQLPostgresConfiguration(
    hostname: "localhost",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
)
```

URL-based configuration is also supported.

```swift
guard let configuration = SQLPostgresConfiguration(url: "postgres://...") else {
    ...
}
```

To connect via unix-domain sockets, use ``SQLPostgresConfiguration/init(unixDomainSocketPath:username:password:database:)`` instead of ``SQLPostgresConfiguration/init(hostname:port:username:password:database:tls:)``.

```swift
let configuration = PostgresConfiguration(
    unixDomainSocketPath: "/path/to/socket",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
)
```

### Connection Pool

Once you have a ``SQLPostgresConfiguration``, you can use it to create a connection source and pool.

```swift
let eventLoopGroup: EventLoopGroup = ...
defer { try! eventLoopGroup.syncShutdown() }

let pools = EventLoopGroupConnectionPool(
    source: PostgresConnectionSource(configuration: configuration), 
    on: eventLoopGroup
)
defer { pools.shutdown() }
```

First create a ``PostgresConnectionSource`` using the configuration struct. This type is responsible for creating new connections to your database server as needed.

Next, use the connection source to create an `EventLoopGroupConnectionPool`. You will also need to pass an `EventLoopGroup`. For more information on creating an `EventLoopGroup`, visit [SwiftNIO's documentation]. Make sure to shutdown the connection pool before it deinitializes. 

`EventLoopGroupConnectionPool` is a collection of pools for each event loop. When using `EventLoopGroupConnectionPool` directly, random event loops will be chosen as needed.

```swift
pools.withConnection { conn 
    print(conn) // PostgresConnection on randomly chosen event loop
}
```

To get a pool for a specific event loop, use `pool(for:)`. This returns an `EventLoopConnectionPool`. 

```swift
let eventLoop: EventLoop = ...
let pool = pools.pool(for: eventLoop)

pool.withConnection { conn
    print(conn) // PostgresConnection on eventLoop
}
```

### PostgresDatabase

Both `EventLoopGroupConnectionPool` and `EventLoopConnectionPool` can be used to create instances of `PostgresDatabase`.

```swift
let postgres = pool.database(logger: ...) // PostgresDatabase
let rows = try postgres.simpleQuery("SELECT version();").wait()
```

Visit [PostgresNIO's docs] for more information on using `PostgresDatabase`.

### SQLDatabase

A `PostgresDatabase` can be used to create an instance of `SQLDatabase`.

```swift
let sql = postgres.sql() // SQLDatabase
let planets = try sql.select().column("*").from("planets").all().wait()
```

Visit [SQLKit's docs] for more information on using `SQLDatabase`. 

[SQLKit]: https://github.com/vapor/sql-kit
[SQLKit's docs]: https://api.vapor.codes/sqlkit/documentation/sqlkit
[PostgresNIO]: https://github.com/vapor/postgres-nio
[PostgresNIO's docs]: https://api.vapor.codes/postgresnio/documentation/postgresnio
[AsyncKit]: https://github.com/vapor/async-kit
[PostgresClient]: https://api.vapor.codes/postgresnio/documentation/postgresnio/postgresclient 
[SwiftNIO's documentation]: https://swiftpackageindex.com/apple/swift-nio/documentation/nio
