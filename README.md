# XConn
WAMP Client for Swift

# Installation

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/xconnio/xconn-swift.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "<executable-target-name>", dependencies: [
            // other dependencies
                .product(name: "XConn", package: "xconn-swift"),
        ]),
        // other targets
    ]
)
```

# Client
creating a client:

```swift
import XConn

let client = Client()
// session is an actor
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")

session.onDisconnect { print("disconnected") }

// try await session.leave()
```
Once the session is established, you can perform WAMP actions. Below are examples of all 4 WAMP operations:

# Subscribe to a topic
```swift
func eventHandler(_ event: Event) {
    print("Event received: args=\(event.args), kwargs=\(event.kwargs), details=\(event.details)")
}

let topic = "io.xconn.example"
let subscription = try await session.subscribe(topic: topic, endpoint: eventHandler)

// subscription.unsubscribe()
```

# Publish to a topic
```swift
let topic = "io.xconn.example"
try await session.publish(topic: topic)
try await session.publish(
    topic: topic,
    args: ["Hello", "World!"],
    kwargs: ["Hello World!": "I Love WAMP"],
    options: ["acknowledge": true]
)
```
# Register a procedure
```swift
func echoHandler(_ invocation: Invocation) -> Result {
    print("Received args=\(String(describing: invocation.args)), kwargs=\(String(describing: invocation.kwargs))")
    return Result(args: invocation.args, kwargs: invocation.kwargs)
}
let procedure = "io.xconn.echo"
let registration = try await session.register(procedure: procedure, endpoint: echoHandler)

// registration.unregister()
```
# Call a procedure
```swift
let result = try await session.call(
    procedure: procedure,
    args: ["Hello", "World!"],
    kwargs: ["Hello World!": "I Love WAMP"]
)
 print("Received args=\(String(describing: result.args)), kwargs=\(String(describing: result.kwargs))")
```

# Authentication
## Ticket Auth
```swift
let authenticator = TicketAuthenticator(authID: "authID", ticket: "ticket")
let client = Client(authenticator: authenticator)
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")
```
## Challenge Response Auth
```swift
let authenticator = CRAAuthenticator(authID: "authID", secret: "secret")
let client = Client(authenticator: authenticator)
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")
```
## Cryptosign Auth
```swift
let authenticator = try CryptoSignAuthenticator(authID: "authID", privateKey: "private-key")
let client = Client(authenticator: authenticator)
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")
```