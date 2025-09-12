import Foundation
import XConn

let testTopic = "io.xconn.test"

let client = Client()
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")

let subscription = try await session.subscribe(topic: testTopic) { event in
    print(
        "Received Event: args=\(String(describing: event.args)), " +
            "kwargs=\(String(describing: event.kwargs)), " +
            "details=\(event.details)"
    )
}

print("Subscribed to the topic: \(testTopic)")

let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
signal(SIGINT, SIG_IGN) // ignore default handling

await withCheckedContinuation { continuation in
    session.onDisconnect {
        print("Disconnected....")
        exit(EXIT_FAILURE)
    }

    source.setEventHandler {
        print("\nCtrl+C detected. Cleaning up...")

        Task {
            do {
                try await subscription.unsubscribe()
                try await session.leave()
                print("Cleanup completed successfully")
            } catch {
                print("Error during cleanup: \(error)")
            }
            continuation.resume()
            exit(EXIT_SUCCESS)
        }
        source.cancel()
    }
    source.resume()
}
