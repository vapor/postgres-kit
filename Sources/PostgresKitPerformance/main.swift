import NIO
import PostgresKit

let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
let db = PostgresConnectionSource(config: .init(hostname: "localhost", username: "vapor_username", password: "vapor_password", database: "vapor_database"), on: eventLoop)
let conn = try db.makeConnection().wait()

_ = try conn.simpleQuery("SELECT * FROM generate_series(1, 100000) num").wait()

print("Done")
