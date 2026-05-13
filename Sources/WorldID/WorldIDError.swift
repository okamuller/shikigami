import Foundation

/// Errors that can occur during World ID verification or purchase flows.
public enum WorldIDError: Error, Equatable, Sendable {

    /// The proof was rejected by the World ID developer portal (invalid or already used).
    case proofInvalid(detail: String)

    /// The same nullifier_hash was already used for this action (double-spend attempt).
    case alreadyVerified

    /// The request to the verification or shop endpoint failed at the network level.
    case networkFailure(URLError)

    /// The server returned an unexpected HTTP status code.
    case httpError(statusCode: Int, body: String)

    /// The response body could not be decoded.
    case decodingFailed(String)

    // URLError is not Equatable; compare by code only for test convenience.
    public static func == (lhs: WorldIDError, rhs: WorldIDError) -> Bool {
        switch (lhs, rhs) {
        case (.proofInvalid(let a), .proofInvalid(let b)):     return a == b
        case (.alreadyVerified, .alreadyVerified):             return true
        case (.networkFailure(let a), .networkFailure(let b)): return a.code == b.code
        case (.httpError(let a, _), .httpError(let b, _)):     return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)): return a == b
        default: return false
        }
    }
}
