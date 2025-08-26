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

    var goodbyeContinuation: CheckedContinuation<Void, Never>?

    var idgen: SessionScopeIDGenerator = .init()

    public init(baseSession: BaseSession) {
        self.baseSession = baseSession
        wampSession = Wampproto.Session(serializer: baseSession.serializer)
        Task {
            try await wait()
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
        default:
            print("Received unknown message: \(message)")
        }
    }

    private func sendMessage(message: Message) async throws {
        let data = try wampSession.sendMessage(msg: message)
        return try await baseSession.send(webSocketMessage: data.webSocketMessage())
    }
}
