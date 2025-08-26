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
        while true {
            do {
                let data = try await baseSession.receiveMessage()
                try await processIncomingMessage(data)
            } catch {
                print("Error waiting for message: \(error)")
            }
        }
    }

    private func processIncomingMessage(_: Wampproto.Message) async throws {}

    private func sendMessage(message: Message) async throws {
        let data = try wampSession.sendMessage(msg: message)
        return try await baseSession.send(webSocketMessage: data.webSocketMessage())
    }
}
