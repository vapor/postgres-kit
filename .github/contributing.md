# Contributing to PostgresKit

👋 Welcome to the Vapor team! 

## Docker

This package includes a `docker-compose` file you can use for spinning up test databases with test credentials. 

```sh
$ docker-compose up psql-11
```

## Testing

Once in Xcode, select the `postgres-kit` scheme and use `CMD+U` to run the tests.

You can also test via the CLI using `swift test`.

If you are fixing a single GitHub issue in particular, you can add a test named `testGH<issue number>` to ensure
that your fix is working. This will also help prevent regression.

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

----------

Join us on Discord if you have any questions: [discord.gg/vapor](https://discord.gg/vapor).

&mdash; Thanks! 🙌
