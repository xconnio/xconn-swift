import Testing
@preconcurrency import Wampproto
@testable import XConn

struct ClientTests {
    @Test func manageWAMPConnection() async throws {
        let client = Client()
        let sessionActor = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")
        #expect(await sessionActor.isConnected)
        try await sessionActor.leave()
        #expect(await !sessionActor.isConnected)
    }
}
