import Foundation
import XConn

let testProcedureSum = "xconn.io.sum"
let testProcedureEcho = "xconn.io.echo"

let client = Client()
let session = try await client.connect(uri: "ws://localhost:8080/ws", realm: "realm1")

func printCallResult(_ procedure: String, _ result: Result) {
    let argsDescription = String(describing: result.args)
    let kwargsDescription = String(describing: result.kwargs)
    let printString = "Result of procedure call \(procedure): " +
        "args=\(argsDescription), " +
        "kwargs=\(kwargsDescription)\n"

    print(printString)
}

do {
    let echoResult = try await session.call(
        procedure: testProcedureEcho,
        args: ["hello", "world"],
        kwargs: ["key": "value"]
    )
    printCallResult(testProcedureEcho, echoResult)

    let sumResult = try await session.call(procedure: testProcedureSum, args: [1, 2, 3])
    printCallResult(testProcedureSum, sumResult)

} catch {
    print("Error: \(error)")
}

try await session.leave()
