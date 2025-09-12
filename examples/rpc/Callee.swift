import Foundation
import XConn

let testTopic = "io.xconn.test"

let client = Client()
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")

func sumHanlder(_ invocation: Invocation) -> Result {
    print("Received args=\(String(describing: invocation.args)), kwargs=\(String(describing: invocation.kwargs))")
    var sum = 0
    for arg in invocation.args ?? [] {
        if let intArg = arg as? Int {
            sum += intArg
        }
    }
    return Result(args: [sum])
}

func echoHandler(_ invocation: Invocation) -> Result {
    print("Received args=\(String(describing: invocation.args)), kwargs=\(String(describing: invocation.kwargs))")
    return Result(args: invocation.args, kwargs: invocation.kwargs)
}

func noResultHandler(_ invocation: Invocation) -> Result {
    print("Received args=\(String(describing: invocation.args)), kwargs=\(String(describing: invocation.kwargs))")
    return Result()
}

_ = try await session.register(procedure: "sum", endpoint: sumHanlder)
print("Registered procedure: 'sum'")

_ = try await session.register(procedure: "echo", endpoint: echoHandler)
print("Registered procedure: 'echo'")

_ = try await session.register(procedure: "noResult", endpoint: noResultHandler)
print("Registered procedure: 'noResult'")

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
