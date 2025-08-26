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

    private var callRequests: [Int64: CheckedContinuation<XConn.Result, Swift.Error>] = [:]
    private var registerRequests: [Int64: RegisterRequest] = [:]
    private var registrations: [Int64: ProcedureHandler] = [:]
    private var unregisterRequests: [Int64: UnregisterRequest] = [:]

    private var goodbyeContinuation: CheckedContinuation<Void, Never>?

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
        options: SendableDict = [:]
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

    public func register(
        procedure: String,
        endpoint: @escaping ProcedureHandler,
        options: SendableDict = [:]
    ) async throws -> Registration {
        let registerMessage = Wampproto.Register(
            withFields: RegisterFields(requestID: idgen.next(), uri: procedure, options: options)
        )

        try await sendMessage(message: registerMessage)

        return try await withCheckedThrowingContinuation { continuation in
            registerRequests[registerMessage.requestID] = RegisterRequest(
                continuation: continuation,
                endpoint: endpoint
            )
        }
    }

    public func unregister(registrationID: Int64) async throws {
        let unregisterMessage = Wampproto.Unregister(
            withFields: UnregisterFields(requestID: idgen.next(), registrationID: registrationID)
        )

        try await sendMessage(message: unregisterMessage)

        return try await withCheckedThrowingContinuation { continuation in
            unregisterRequests[unregisterMessage.requestID] = UnregisterRequest(
                continuation: continuation,
                registrationID: unregisterMessage.registrationID
            )
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
        case let msg as Wampproto.Invocation:
            if let endpoint = registrations[msg.registrationID] {
                let invocation = XConn.Invocation(args: msg.args, kwargs: msg.kwargs, details: msg.details)
                let result = try await endpoint(invocation)
                let yield = Yield(
                    withFields: YieldFields(
                        requestID: msg.requestID,
                        args: result.args,
                        kwargs: result.kwargs,
                        options: result.details
                    )
                )
                try await baseSession.sendMessage(message: yield)
            }
        case let msg as Registered:
            if let request = registerRequests.removeValue(forKey: msg.requestID) {
                registrations[msg.registrationID] = request.endpoint
                request.continuation.resume(
                    returning: Registration(registrationID: msg.registrationID, session: self)
                )
            }
        case let msg as Wampproto.Unregistered:
            if let request = unregisterRequests[msg.requestID] {
                registrations.removeValue(forKey: request.registrationID)
                unregisterRequests.removeValue(forKey: msg.requestID)
                request.continuation.resume(returning: ())
            }
        case let msg as Wampproto.Error:
            let error = ApplicationError(message: msg.uri, args: msg.args, kwargs: msg.kwargs)
            let invalidRequestMessage = "Received \(type(of: msg).text) message for invalid request ID"
            let invalidRequestError = RequestError.invalid(invalidRequestMessage)

            switch msg.messageType {
            case Wampproto.Call.id:
                guard let continuation = callRequests.removeValue(forKey: msg.requestID) else {
                    throw invalidRequestError
                }

                continuation.resume(throwing: error)
            case Wampproto.Register.id:
                guard let request = registerRequests.removeValue(forKey: msg.requestID) else {
                    throw invalidRequestError
                }

                request.continuation.resume(throwing: error)
            case Wampproto.Unregister.id:
                guard let request = unregisterRequests.removeValue(forKey: msg.requestID) else {
                    throw invalidRequestError
                }
                request.continuation.resume(throwing: error)
            default:
                throw ProtocolError(message: msg.uri)
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
