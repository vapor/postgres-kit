# Contributing to PostgreSQL

👋 Welcome to the Vapor team! 

## Bootstrap

To prepare your computer for developing this package, you can run the bootstrap script.

```sh
./contribute_boostrap.sh
```

This script will start up a PostgreSQL docker container to test against. It will also generate and open Xcode for you.

Be careful to observe the script's output, it may have errors or ask you to do additional steps manually.

## Testing

Once in Xcode, select the `PostgreSQL-Package` scheme and use `CMD+U` to run the tests.

When adding new tests (please do 😁), don't forget to add the method name to the `allTests` array. 
If you add a new `XCTestCase` subclass, make sure to add it to the `Tests/LinuxMain.swift` file.

If you are fixing a single GitHub issue in particular, you can add a test named `testGH<issue number>` to ensure
that your fix is working. This will also help prevent regression.

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

----------

Join us on Slack if you have any questions: [http://vapor.team](http://vapor.team).

&mdash; Thanks! 🙌
