<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/vapor/postgres-kit/assets/1130717/02ca33b1-d788-4846-8280-7cd89f09c397">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/vapor/postgres-kit/assets/1130717/91de055b-0e4f-42f3-8257-946ac40d731c">
  <img src="https://github.com/vapor/postgres-kit/assets/1130717/91de055b-0e4f-42f3-8257-946ac40d731c" height="96" alt="PostgresKit">
</picture> 
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/postgres-kit/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/postgres-kit/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/postgres-kit"><img src="https://img.shields.io/codecov/c/github/vapor/postgres-kit?style=plastic&logo=codecov&label=codecov"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift59up.svg" alt="Swift 5.9+"></a>
</p>

<br>

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

PostgresKit is an [SQLKit] driver for PostgreSQL clients. It supports building and serializing Postgres-dialect SQL queries. PostgresKit uses [PostgresNIO] to connect and communicate with the database server asynchronously. [AsyncKit](https://github.com/vapor/async-kit) is used to provide connection pooling.

> [!IMPORTANT]
> It is strongly recommended that users who leverage PostgresKit directly (e.g. absent the Fluent ORM layer) take advantage of PostgresNIO's [PostgresClient] API for connection management rather than relying upon the legacy AsyncKit API.

[SQLKit]: https://github.com/vapor/sql-kit
[PostgresNIO]: https://github.com/vapor/postgres-nio
[AsyncKit]: https://github.com/vapor/async-kit
[PostgresClient]: https://api.vapor.codes/postgresnio/documentation/postgresnio/postgresclient 

### Configuration

Database connection options and credentials are specified using a `PostgresConfiguration` struct. 

```swift
import PostgresKit

let configuration = PostgresConfiguration(
    hostname: "localhost",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
)
```

URL string based configuration is also supported.

```swift
guard let configuration = PostgresConfiguration(url: "postgres://...") else {
    ...
}
```

To connect via unix-domain sockets, use `unixDomainSocketPath` instead of `hostname` and `port`.

```swift
let configuration = PostgresConfiguration(
    unixDomainSocketPath: "/path/to/socket",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
)
```

### Connection Pool

Once you have a `PostgresConfiguration`, you can use it to create a connection source and pool.

```swift
let eventLoopGroup: EventLoopGroup = ...
defer { try! eventLoopGroup.syncShutdown() }

let pools = EventLoopGroupConnectionPool(
    source: PostgresConnectionSource(configuration: configuration), 
    on: eventLoopGroup
)
defer { pools.shutdown() }
```

First create a `PostgresConnectionSource` using the configuration struct. This type is responsible for creating new connections to your database server as needed.

Next, use the connection source to create an `EventLoopGroupConnectionPool`. You will also need to pass an `EventLoopGroup`. For more information on creating an `EventLoopGroup`, visit SwiftNIO's [documentation](https://apple.github.io/swift-nio/docs/current/NIO/index.html). Make sure to shutdown the connection pool before it deinitializes. 

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

Visit [PostgresNIO's docs](https://github.com/vapor/postgres-nio) for more information on using `PostgresDatabase`.

### SQLDatabase

A `PostgresDatabase` can be used to create an instance of `SQLDatabase`.

```swift
let sql = postgres.sql() // SQLDatabase
let planets = try sql.select().column("*").from("planets").all().wait()
```

Visit [SQLKit's docs](https://github.com/vapor/sql-kit) for more information on using `SQLDatabase`. 
