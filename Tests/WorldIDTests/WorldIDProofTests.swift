import XCTest
@testable import WorldID

final class WorldIDProofTests: XCTestCase {

    // MARK: Codable round-trip

    func test_proof_encodes_snake_case_keys() throws {
        let proof = WorldIDProof(
            merkleRoot: "0xabc",
            nullifierHash: "0xdef",
            proof: "0x123",
            verificationLevel: .orb
        )
        let data = try JSONEncoder().encode(proof)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: String]

        XCTAssertEqual(json["merkle_root"],       "0xabc")
        XCTAssertEqual(json["nullifier_hash"],    "0xdef")
        XCTAssertEqual(json["proof"],             "0x123")
        XCTAssertEqual(json["verification_level"], "orb")
    }

    func test_proof_decodes_from_snake_case_json() throws {
        let json = """
        {
          "merkle_root": "0xaaa",
          "nullifier_hash": "0xbbb",
          "proof": "0xccc",
          "verification_level": "device"
        }
        """.data(using: .utf8)!

        let proof = try JSONDecoder().decode(WorldIDProof.self, from: json)

        XCTAssertEqual(proof.merkleRoot,       "0xaaa")
        XCTAssertEqual(proof.nullifierHash,    "0xbbb")
        XCTAssertEqual(proof.proof,            "0xccc")
        XCTAssertEqual(proof.verificationLevel, .device)
    }

    // MARK: Equatable

    func test_two_identical_proofs_are_equal() {
        let a = WorldIDProof(merkleRoot: "r", nullifierHash: "n", proof: "p", verificationLevel: .orb)
        let b = WorldIDProof(merkleRoot: "r", nullifierHash: "n", proof: "p", verificationLevel: .orb)
        XCTAssertEqual(a, b)
    }

    func test_proofs_differ_on_nullifier() {
        let a = WorldIDProof(merkleRoot: "r", nullifierHash: "n1", proof: "p", verificationLevel: .orb)
        let b = WorldIDProof(merkleRoot: "r", nullifierHash: "n2", proof: "p", verificationLevel: .orb)
        XCTAssertNotEqual(a, b)
    }

    // MARK: Verification level

    func test_verification_level_orb_raw_value() {
        XCTAssertEqual(WorldIDProof.VerificationLevel.orb.rawValue, "orb")
    }

    func test_verification_level_device_raw_value() {
        XCTAssertEqual(WorldIDProof.VerificationLevel.device.rawValue, "device")
    }
}
