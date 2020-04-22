<p align="center">
    <img 
        src="https://user-images.githubusercontent.com/1342803/59063319-d190f500-8875-11e9-8fe6-16197dd56d0f.png" 
        height="64" 
        alt="PostgresKit" 
    >
    <br>
    <br>
    <a href="https://docs.vapor.codes/4.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://img.shields.io/discord/431917998102675485.svg" alt="Team Chat">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://github.com/vapor/sql-kit/actions">
        <img src="https://github.com/vapor/sql-kit/workflows/test/badge.svg" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
</p>

---

```swift
import Vapor
import PostgresKit

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

let postgres = PostgresConnectionSource(configuration: .init(
    hostname: "localhost",
    username: "vapor_username",
    password: "vapor_password",
    database: "vapor_database"
))

let pools = EventLoopGroupConnectionPool(source: postgres, on: app.eventLoopGroup)
defer { pools.shutdown() }

app.get("version") { req -> EventLoopFuture<String> in
    pools.pool(for: req.eventLoop)
        .database(logger: req.logger)
        .sql()
        .raw("SELECT version()")
        .all()
        .map
    {
        $0.description
    }
}

try app.run()
```
