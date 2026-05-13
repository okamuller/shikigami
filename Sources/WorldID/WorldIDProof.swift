import Foundation

/// Zero-knowledge proof returned by the World App after a successful verification.
/// Mirrors the payload described in the World ID documentation:
/// https://docs.worldcoin.org/reference/contracts
public struct WorldIDProof: Equatable, Sendable, Codable {

    public enum VerificationLevel: String, Codable, Sendable, Equatable {
        /// Verified via the Orb (biometric, highest assurance).
        case orb = "orb"
        /// Verified via the World App on-device (lower assurance).
        case device = "device"
    }

    /// Root of the current Merkle tree of verified identities.
    public let merkleRoot: String
    /// Unique nullifier — prevents the same identity from submitting twice
    /// for the same action.
    public let nullifierHash: String
    /// Groth16 ZK proof, ABI-encoded hex string.
    public let proof: String
    /// Assurance level of the verification.
    public let verificationLevel: VerificationLevel

    public init(
        merkleRoot: String,
        nullifierHash: String,
        proof: String,
        verificationLevel: VerificationLevel
    ) {
        self.merkleRoot = merkleRoot
        self.nullifierHash = nullifierHash
        self.proof = proof
        self.verificationLevel = verificationLevel
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case merkleRoot       = "merkle_root"
        case nullifierHash    = "nullifier_hash"
        case proof
        case verificationLevel = "verification_level"
    }
}
