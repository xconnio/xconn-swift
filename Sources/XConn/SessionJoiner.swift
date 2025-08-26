//
//  SessionJoiner.swift
//  XConn
//
//  Created by Ismail Akram on 15.08.25.
//

import Foundation
import Wampproto

public final class SessionJoiner: Sendable {
    public let authenticator: ClientAuthenticator
    public let serializer: Serializer

    public init(authenticator: ClientAuthenticator, serializer: Serializer = JSONSerializer()) {
        self.authenticator = authenticator
        self.serializer = serializer
    }

    public func join(uri: String, realm: String) async throws -> BaseSession {
        let websocketTask = connect(uri: uri)

        var joiner = Joiner(realm: realm, serializer: serializer, authenticator: authenticator)
        let helloWebSocketMessage = try joiner.sendHello().webSocketMessage()
        try await websocketTask.send(helloWebSocketMessage)

        let response = try await websocketTask.receive()
        let serializedMessage = response.serializedMessage()

        if let authenticateMessage = try joiner.receive(data: serializedMessage) {
            try await websocketTask.send(authenticateMessage.webSocketMessage())
        }

        let sessionDetails = try joiner.getSessionDetails()

        // return joiner.getSessionDetails()
        return BaseSession(
            task: websocketTask,
            sessionDetails: sessionDetails,
            serializer: serializer
        )
    }

    func connect(uri: String) -> URLSessionWebSocketTask {
        let url = URL(string: uri)!
        let websocketTask = URLSession.shared.webSocketTask(with: url, protocols: [subProtocol])
        websocketTask.resume()

        return websocketTask
    }

    var subProtocol: String {
        switch serializer {
        case is JSONSerializer:
            "wamp.2.json"
        case is MsgPackSerializer:
            "wamp.2.msgpack"
        case is CBORSerializer:
            "wamp.2.cbor"
        default:
            fatalError("Unsupported serializer")
        }
    }
}
