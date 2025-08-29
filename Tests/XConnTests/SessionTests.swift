import Testing
@testable import XConn

let serializers: [Serializer] = [JSONSerializer(), CBORSerializer(), MsgPackSerializer()]
let authenticators: [Authenticator] = [
    AnonymousAuthenticator(authID: "anonymous"),
    TicketAuthenticator(authID: "ticket-user", ticket: "ticket-pass"),
    CRAAuthenticator(authID: "wamp-cra-user", secret: "cra-secret")
    // CRAAuthenticator(authID: "wamp-cra-salt-user", secret: "cra-salt-secret")
]

@Test(arguments: serializers, authenticators)
func checkRPCMethods(serializer: Serializer, authenticator: Authenticator) async throws {
    // creates WAMP session
    let client = Client(authenticator: authenticator, serializer: serializer)
    let session = try await client.connect(uri: "ws://localhost:8080", realm: "realm1")
    // procedure to register and call
    let procedure = "echo-\(type(of: serializer))-\(type(of: authenticator))-\(authenticator.authID)"

    // Register a procedure
    let registration = try await session.register(
        procedure: procedure,
        endpoint: { _ in Result(args: ["hello"], kwargs: ["age": 123.23]) }
    )
    // Call the procedure
    let result = try await session.call(procedure: procedure)

    guard let value = result.args?.first as? String else {
        print("Unexpected result format: \(result)")
        return
    }

    #expect(value == "hello")

    try await registration.unregister()

    await #expect(throws: (any Error).self) {
        try await session.call(procedure: procedure)
    }

    try await session.leave()
}

@Test(arguments: zip(serializers, authenticators))
func checkPubSubMethods(_ serializer: Serializer, _ authenticator: Authenticator) async throws {
    let client = Client(authenticator: authenticator, serializer: serializer)
    let session = try await client.connect(uri: "ws://localhost:8080", realm: "realm1")
    let topic = "topic-\(type(of: serializer))-\(type(of: authenticator))-\(authenticator.authID)"

    let subscription = try await session.subscribe(topic: topic) { event in
        guard let value = event.args?.first as? String else {
            print("Unexpected result format: \(event)")
            return
        }
        #expect(value == "hello")
    }

    try await session.publish(topic: topic, args: ["hello"], kwargs: ["age": 25.2])

    try await subscription.unsubscribe()

    try await session.leave()
}
