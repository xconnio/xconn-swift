import Wampproto

public class Client {
    let authenticator: ClientAuthenticator
    let serializer: Serializer

    public init(
        authenticator: ClientAuthenticator = AnonymousAuthenticator(authID: ""),
        serializer: Serializer = JSONSerializer()
    ) {
        self.authenticator = authenticator
        self.serializer = serializer
    }

    public func connect(uri: String, realm: String) async throws -> Session {
        let joiner = SessionJoiner(authenticator: authenticator, serializer: serializer)
        let baseSession = try await joiner.join(uri: uri, realm: realm)
        let session = Session(baseSession: baseSession)
        return session
    }
}
