# ``PostgresKit``

@Metadata {
    @TitleHeading(Package)
}

PostgresKit is a library providing an SQLKit driver for PostgresNIO.

## Overview

This package provides the "foundational" level of support for using [Fluent] with PostgreSQL by implementing the requirements of an [SQLKit] driver. It is responsible for:

- Managing the underlying PostgreSQL library ([PostgresNIO]),
- Providing a two-way bridge between PostgresNIO and SQLKit's generic data and metadata formats, and
- Presenting an interface for establishing, managing, and interacting with database connections via [AsyncKit].

> Important: It is strongly recommended that users who leverage PostgresKit directly (e.g. absent the Fluent ORM layer) take advantage of PostgresNIO's [PostgresClient] API for connection management rather than relying upon the legacy AsyncKit-based support.

> Tip: A FluentKit driver for PostgreSQL is provided by the [FluentPostgresDriver] package.

## Version Support

This package uses [PostgresNIO] for all underlying database interactions. It is compatible with all versions of PostgreSQL and all platforms supported by that package.

> Caution: There is one exception to the above at the time of this writing: This package requires Swift 5.8 or newer, whereas PostgresNIO continues to support Swift 5.6.

[SQLKit]: https://swiftpackageindex.com/vapor/sql-kit
[PostgresNIO]: https://swiftpackageindex.com/vapor/postgres-nio
[Fluent]: https://swiftpackageindex.com/vapor/fluent-kit
[FluentPostgresDriver]: https://swiftpackageindex.com/vapor/fluent-postgres-driver
[AsyncKit]: https://swiftpackageindex.com/vapor/async-kit
[PostgresClient]: https://api.vapor.codes/postgresnio/documentation/postgresnio/postgresclient 
