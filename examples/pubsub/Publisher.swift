import XConn

let testTopic = "io.xconn.test"

let client = Client()
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")

try await session.publish(topic: testTopic)

try await session.publish(topic: testTopic, args: ["Hello", "World"])

try await session.publish(topic: testTopic, kwargs: ["Hello World!": "I Love WAMP"])

try await session.publish(
    topic: testTopic,
    args: ["Hello", "World!"],
    kwargs: ["Hello World!": "I Love WAMP"],
    options: ["acknowledge": true]
)

try await session.leave()
