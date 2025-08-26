//
//  SessionJoinerTests.swift
//  XConn
//
//  Created by Ismail Akram on 19.08.25.
//

import Testing
@testable import XConn

let args: [Serializer] = [JSONSerializer(), MsgPackSerializer(), CBORSerializer()]
struct SessionJoinerTests {
    let authId = "1"
    let testRealm = "test.realm"
    let testSessionID: Int64 = 12345
    let testAuthID = "test_authid"
    let testAuthRole = "test_role"
    let testAuthMethod = "anonymous"

    @Test("Joins with different serializers", arguments: args)
    func usingAnonymousAuthenticator(_ serializer: XConn.Serializer) async throws {
        let joiner = SessionJoiner(
            authenticator: AnonymousAuthenticator(authID: ""),
            serializer: serializer
        )
        let session = try await joiner.join(uri: "ws://localhost:8080/ws", realm: "realm1")
        #expect(!session.authid.isEmpty == false)
    }
}
