//
//  Types.swift
//  XConn
//
//  Created by Ismail Akram on 15.08.25.
//
import Foundation
import Wampproto

// PUBLIC API

// Authenticator Types
public typealias Authenticator = Wampproto.ClientAuthenticator

public typealias AnonymousAuthenticator = Wampproto.AnonymousAuthenticator
public typealias CRAAuthenticator = Wampproto.CRAAuthenticator
public typealias CryptoSignAuthenticator = Wampproto.CryptoSignAuthenticator
public typealias TicketAuthenticator = Wampproto.TicketAuthenticator

// Serializers
public typealias Serializer = Wampproto.Serializer

public typealias JSONSerializer = Wampproto.JSONSerializer
public typealias MsgPackSerializer = Wampproto.MsgPackSerializer
public typealias CBORSerializer = Wampproto.CBORSerializer
public typealias SerializedMessage = Wampproto.SerializedMessage

// Args
public typealias Arguments = [any Sendable]
public typealias KeywordArguments = [String: any Sendable]
public typealias DefaultOptions = [String: any Sendable]
public typealias SendableDict = DefaultOptions

// Callbacks/Handlers
public typealias ProcedureHandler = (Invocation) async throws -> Result
public typealias EventHandler = (Event) async throws -> Void

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
    var id: UInt64 { get }
    var realm: String { get }
    var authid: String { get }
    var authrole: String { get }
    var serializer: Serializer { get }
    func send(webSocketMessage: URLSessionWebSocketTask.Message) async throws
    func receive() async throws -> URLSessionWebSocketTask.Message
    func sendMessage(message: Message) async throws
    func receiveMessage() async throws -> Message
}

public final class BaseSession: BaseSessionProtocol, Sendable {
    public let task: URLSessionWebSocketTask
    let sessionDetails: SessionDetails
    let serializer: Serializer

    init(task: URLSessionWebSocketTask, sessionDetails: SessionDetails, serializer: Serializer) {
        self.task = task
        self.sessionDetails = sessionDetails
        self.serializer = serializer
    }

    public var id: UInt64 {
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

    public func leave() async throws {
        let reason = Data("Client left".utf8)
        task.cancel(with: URLSessionWebSocketTask.CloseCode.goingAway, reason: reason)
    }
}

public struct Result: Sendable {
    public var args: Arguments?
    public var kwargs: KeywordArguments?
    public var details: SendableDict = [:]

    public init(args: Arguments? = nil, kwargs: KeywordArguments? = nil, details: SendableDict = [:]) {
        self.args = args
        self.kwargs = kwargs
        self.details = details
    }
}

public struct Invocation: Sendable {
    public var args: Arguments?
    public var kwargs: KeywordArguments?
    public var details: SendableDict = [:]
    public init(args: Arguments? = nil, kwargs: KeywordArguments? = nil, details: SendableDict = [:]) {
        self.args = args
        self.kwargs = kwargs
        self.details = details
    }
}

public struct RegisterRequest {
    let continuation: CheckedContinuation<XConn.Registration, Swift.Error>
    let endpoint: ProcedureHandler
}

public struct Registration: Sendable {
    public var registrationID: UInt64
    var session: Session

    public func unregister() async throws {
        try await session.unregister(registrationID: registrationID)
    }
}

public struct UnregisterRequest {
    let continuation: CheckedContinuation<Void, Swift.Error>
    let registrationID: UInt64
}

public struct SubscribeRequest {
    let continuation: CheckedContinuation<XConn.Subscription, Swift.Error>
    let endpoint: EventHandler
}

public struct Subscription: Sendable {
    public var subscriptionID: UInt64
    var session: Session

    public func unsubscribe() async throws {
        try await session.unsubscribe(subscriptionID: subscriptionID)
    }
}

public struct UnsubscribeRequest {
    let continuation: CheckedContinuation<Void, Swift.Error>
    let subscriptionID: UInt64
}

public struct Event: Sendable {
    public var args: Arguments?
    public var kwargs: KeywordArguments?
    public var details: SendableDict = [:]
    public init(args: Arguments? = nil, kwargs: KeywordArguments? = nil, details: SendableDict = [:]) {
        self.args = args
        self.kwargs = kwargs
        self.details = details
    }
}

public enum RequestError: Swift.Error {
    case invalid(String)
}

public enum SubprotocolError: Swift.Error {
    case unsupported(String)
}
