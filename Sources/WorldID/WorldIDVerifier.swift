import Foundation

/// Verifies a World ID proof against the World ID developer portal.
///
/// Inject a concrete implementation (``WorldIDVerificationService``) in production
/// and a stub in tests.
public protocol WorldIDVerifier: Sendable {

    /// Calls the World ID developer-portal verification endpoint and returns
    /// the nullifier hash on success, which the caller can persist to prevent
    /// replays.
    ///
    /// - Parameters:
    ///   - proof:   The ZK proof received from the World App.
    ///   - appID:   Your World ID app identifier (e.g. `"app_staging_abc123"`).
    ///   - action:  The action identifier configured in the developer portal
    ///              (e.g. `"purchase"`).
    ///   - signal:  An optional binding value (e.g. order ID or user ID).
    ///              Pass `""` when no signal is needed.
    /// - Returns: The `nullifier_hash` confirming successful verification.
    /// - Throws: ``WorldIDError``
    func verify(
        proof: WorldIDProof,
        appID: String,
        action: String,
        signal: String
    ) async throws -> String
}
