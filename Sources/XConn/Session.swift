//
//  Session.swift
//  XConn
//
//  Created by Ismail Akram on 19.08.25.
//

import Foundation
import Wampproto

public actor Session {
    var baseSession: BaseSession
    var wampSession: Wampproto.Session
    var isConnected: Bool = true

    var callRequests: [Int64: CheckedContinuation<XConn.Result, Swift.Error>] = [:]

    var goodbyeContinuation: CheckedContinuation<Void, Never>?

    var idgen: SessionScopeIDGenerator = .init()

    public init(baseSession: BaseSession) {
        self.baseSession = baseSession
        wampSession = Wampproto.Session(serializer: baseSession.serializer)
        Task {
            try await wait()
        }
    }

    public func call(
        procedure: String,
        args: Arguments? = nil,
        kwargs: KeywordArguments? = nil,
        options: DefaultOptions = [:]
    ) async throws -> XConn.Result {
        let callMessage = Wampproto.Call(
            withFields: CallFields(
                requestID: idgen.next(),
                uri: procedure,
                args: args,
                kwargs: kwargs,
                options: options
            )
        )

        try await sendMessage(message: callMessage)

        return try await withCheckedThrowingContinuation { continuation in
            callRequests[callMessage.requestID] = continuation
        }
    }

    public func next() -> Int64 {
        idgen.next()
    }

    public func wait() async throws {
        while isConnected {
            do {
                let data = try await baseSession.receiveMessage()
                try await processIncomingMessage(data)
            } catch {
                print("Error waiting for message: \(error)")
            }
        }
    }

    public func leave() async throws {
        let goodbyeMessage: Message = Goodbye(details: [:], reason: "wamp.close.close_realm")
        try await sendMessage(message: goodbyeMessage)

        return await withCheckedContinuation { continuation in
            self.goodbyeContinuation = continuation
        }
    }

    private func processIncomingMessage(_ message: Wampproto.Message) async throws {
        print("Incoming Message")
        switch message {
        case _ as Goodbye:
            if let continuation = goodbyeContinuation {
                continuation.resume(returning: ())
            }
            isConnected = false
            try await baseSession.leave()
        case let msg as Wampproto.Result:
            if let continuation = callRequests.removeValue(forKey: msg.requestID) {
                let result = XConn.Result(args: msg.args, kwargs: msg.kwargs, details: msg.details)
                continuation.resume(returning: result)
            }
        default:
            print("Received unknown message: \(message)")
        }
    }

    private func sendMessage(message: Message) async throws {
        let data = try wampSession.sendMessage(msg: message)
        return try await baseSession.send(webSocketMessage: data.webSocketMessage())
    }
}
