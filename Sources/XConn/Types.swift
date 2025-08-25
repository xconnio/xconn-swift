//
//  Types.swift
//  XConn
//
//  Created by Ismail Akram on 15.08.25.
//
import Foundation
import Wampproto

extension SerializedMessage {
    func webSocketMessage() -> URLSessionWebSocketTask.Message {
        switch self {
        case let .string(string):
            .string(string)
        case let .data(data):
            .data(data)
        }
    }
}

extension URLSessionWebSocketTask.Message {
    func serializedMessage() -> SerializedMessage {
        switch self {
        case let .string(string):
            return .string(string)
        case let .data(data):
            return .data(data)
        @unknown default:
            fatalError()
        }
    }
}

protocol BaseSessionProtocol {
    var id: Int64 { get }
    var realm: String { get }
    var authid: String { get }
    var authrole: String { get }
    var serializer: Serializer { get }
    func send(webSocketMessage: URLSessionWebSocketTask.Message) async throws
    func receive() async throws -> URLSessionWebSocketTask.Message
    func sendMessage(message: Message) async throws
    func receiveMessage() async throws -> Message
}

public class BaseSession: BaseSessionProtocol {
    let task: URLSessionWebSocketTask
    let sessionDetails: SessionDetails
    let serializer: Serializer

    init(task: URLSessionWebSocketTask, sessionDetails: SessionDetails, serializer: Serializer) {
        self.task = task
        self.sessionDetails = sessionDetails
        self.serializer = serializer
    }

    public var id: Int64 {
        sessionDetails.sessionID
    }

    public var realm: String {
        sessionDetails.realm
    }

    public var authid: String {
        sessionDetails.authID
    }

    public var authrole: String {
        sessionDetails.authRole
    }

    public func send(webSocketMessage: URLSessionWebSocketTask.Message) async throws {
        try await task.send(webSocketMessage)
    }

    public func sendMessage(message: any Message) async throws {
        let data = try serializer.serialize(message: message)
        let webSocketMessage = data.webSocketMessage()
        try await send(webSocketMessage: webSocketMessage)
    }

    public func receive() async throws -> URLSessionWebSocketTask.Message {
        try await task.receive()
    }

    public func receiveMessage() async throws -> any Message {
        let websocketMessage = try await receive()

        return try serializer.deserialize(data: websocketMessage.serializedMessage())
    }
}
