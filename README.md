<p align="center">
<img src="https://design.vapor.codes/images/vapor-postgreskit.svg" height="96" alt="PostgresKit">
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/postgres-kit/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/postgres-kit/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/postgres-kit"><img src="https://img.shields.io/codecov/c/github/vapor/postgres-kit?style=plastic&logo=codecov&label=codecov" alt="Code Coverage"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift60up.svg" alt="Swift 6.0+"></a>
</p>

<br>

PostgresKit is an [SQLKit] driver for PostgreSQL clients.

## Overview

PostgresKit supports building and serializing Postgres-dialect SQL queries using [SQLKit]'s API. PostgresKit uses [PostgresNIO] to connect and communicate with the database server asynchronously. [AsyncKit] is used to provide connection pooling.

> Important: It is strongly recommended that users who leverage PostgresKit directly (e.g. absent the Fluent ORM layer) take advantage of PostgresNIO's [PostgresClient] API for connection management rather than relying upon the legacy AsyncKit API.

### Usage

Reference this package in your `Package.swift` to include it in your project.

```swift
.package(url: "https://github.com/vapor/postgres-kit.git", from: "2.0.0")
```

### Supported Platforms

PostgresKit supports the following platforms:

- Ubuntu 20.04+
- macOS 10.15+

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
let configuration = SQLPostgresConfiguration(
    unixDomainSocketPath: "/path/to/socket",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
)
```

### Connection Pool (Modern PostgresNIO)

You don't need a ``SQLPostgresConfiguration`` to create a `PostgresClient`, an instance of PostgresNIO's modern connection pool. Instead, use `PostgresClient`'s native configuration type:

```swift
let configuration = PostgresClient.Configuration(
    host: "localhost",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database",
    tls: .prefer(.makeClientConfiguration())
)
let psqlClient = PostgresClient(configuration: configuration)

// Start a Task to run the client:
let clientTask = Task { await client.run() }
// Or, if you're using ServiceLifecycle, add the client to a ServiceGroup:
await serviceGroup.addServiceUnlessShutdown(client)
```

You can then lease a `PostgresConnection` from the client:

```swift
try await client.withConnection { conn in
    print(conn) // PostgresConnection managed by PostgresClient's connection pool
}
```

> [!NOTE]
> `PostgresClient.Configuration` does not support URL-based configuration. If you want to handle URLs, you can create an instance of `SQLPostgresConfiguration` and translate it into a `PostgresClient.Configuration`:
> 
> ```swift
> extension PostgresClient.Configuration {
>   init(from configuration: PostgresConnection.Configuration) {
>     let tls: PostgresClient.Configuration.TLS = switch (configuration.tls.isEnforced, configuration.tls.isAllowed) {
>       case (true, _): .require(configuration.tls.sslContext!.configuration)
>       case (_, true): .prefer(configuration.tls.sslContext!.configuration)
>       default: .disable
>     }
> 
>     if let host = configuration.host, let port = configuration.port {
>       self.init(host: host, port: port, username: configuration.username, password: configuration.password, database: configuration.database, tls: tls)
>     } else if let socket = configuration.unixSocketPath {
>       self.init(unixSocketPath: socket, username: configuration.username, password: configuration.password, database: configuration.database)
>     } else {
>       fatalError("Preconfigured channels not supported")
>     }
>   }
> }
> 
> guard let sqlConfiguration = SQLPostgresConfiguration(url: "...") else { ... }
> let clientConfiguration = PostgresClient.Configuration(configuration: sqlConfiguration.coreConfiguration)
> ```

### Connection Pool (Legacy AsyncKit)

> [!WARNING]
> AsyncKit is deprecated; using it is strongly discouraged. You should not use this setup unless you are also working with FluentKit, which at the time of this writing is not compatible with `PostgresClient`.

Once you have a ``SQLPostgresConfiguration``, you can use it to create a connection source and pool.

```swift
let eventLoopGroup: EventLoopGroup = NIOSingletons.posixEventLoopGroup
let pools = EventLoopGroupConnectionPool(
    source: PostgresConnectionSource(configuration: configuration), 
    on: eventLoopGroup
)

// When you're done:
try await pools.shutdownAsync()
```

First create a ``PostgresConnectionSource`` using the configuration struct. This type is responsible for creating new connections to your database server as needed.

Next, use the connection source to create an `EventLoopGroupConnectionPool`. You will also need to pass an `EventLoopGroup`. For more information on creating an `EventLoopGroup`, visit [SwiftNIO's documentation]. Make sure to shutdown the connection pool before it deinitializes. 

`EventLoopGroupConnectionPool` is a collection of pools for each event loop. When using `EventLoopGroupConnectionPool` directly, random event loops will be chosen as needed.

```swift
pools.withConnection { conn in
    print(conn) // PostgresConnection on randomly chosen event loop
}
```

To get a pool for a specific event loop, use `pool(for:)`. This returns an `EventLoopConnectionPool`. 

```swift
let eventLoop: EventLoop = ...
let pool = pools.pool(for: eventLoop)

pool.withConnection { conn in
    print(conn) // PostgresConnection on eventLoop
}
```

### PostgresDatabase

Both `EventLoopGroupConnectionPool` and `EventLoopConnectionPool` can be used to create instances of `PostgresDatabase`.

```swift
let postgres = pool.database(logger: ...) // PostgresDatabase
let rows = try await postgres.simpleQuery("SELECT version()")
```

Visit [PostgresNIO's docs] for more information on using `PostgresDatabase`.

### SQLDatabase

A `PostgresDatabase` can be used to create an instance of `SQLDatabase`.

```swift
let sql = postgres.sql() // SQLDatabase
let planets = try await sql.select().column("*").from("planets").all()
```

Visit [SQLKit's docs] for more information on using `SQLDatabase`. 

[SQLKit]: https://github.com/vapor/sql-kit
[SQLKit's docs]: https://api.vapor.codes/sqlkit/documentation/sqlkit
[PostgresNIO]: https://github.com/vapor/postgres-nio
[PostgresNIO's docs]: https://api.vapor.codes/postgresnio/documentation/postgresnio
[AsyncKit]: https://github.com/vapor/async-kit
[PostgresClient]: https://api.vapor.codes/postgresnio/documentation/postgresnio/postgresclient 
[SwiftNIO's documentation]: https://swiftpackageindex.com/apple/swift-nio/documentation/nio
