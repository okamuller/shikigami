import XCTest
@testable import WorldID

// MARK: - Stub verifier

/// Configurable stub for unit-testing callers of WorldIDVerifier.
final class StubWorldIDVerifier: WorldIDVerifier, @unchecked Sendable {
    var result: Result<String, WorldIDError> = .success("0xnullifier")

    func verify(
        proof: WorldIDProof,
        appID: String,
        action: String,
        signal: String
    ) async throws -> String {
        switch result {
        case .success(let hash): return hash
        case .failure(let err):  throw err
        }
    }
}

// MARK: - Tests

final class WorldIDVerificationServiceTests: XCTestCase {

    private let sampleProof = WorldIDProof(
        merkleRoot: "0xroot",
        nullifierHash: "0xnull",
        proof: "0xproof",
        verificationLevel: .orb
    )

    // MARK: Stub-based flow tests

    func test_stub_returns_nullifier_on_success() async throws {
        let stub = StubWorldIDVerifier()
        stub.result = .success("0xdeadbeef")

        let hash = try await stub.verify(
            proof: sampleProof,
            appID: "app_test",
            action: "purchase",
            signal: "product_001"
        )
        XCTAssertEqual(hash, "0xdeadbeef")
    }

    func test_stub_throws_already_verified() async {
        let stub = StubWorldIDVerifier()
        stub.result = .failure(.alreadyVerified)

        do {
            _ = try await stub.verify(
                proof: sampleProof,
                appID: "app_test",
                action: "purchase",
                signal: ""
            )
            XCTFail("Expected WorldIDError.alreadyVerified")
        } catch WorldIDError.alreadyVerified {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_stub_throws_proof_invalid() async {
        let stub = StubWorldIDVerifier()
        stub.result = .failure(.proofInvalid(detail: "invalid_proof"))

        do {
            _ = try await stub.verify(
                proof: sampleProof,
                appID: "app_test",
                action: "purchase",
                signal: ""
            )
            XCTFail("Expected WorldIDError.proofInvalid")
        } catch WorldIDError.proofInvalid(let detail) {
            XCTAssertEqual(detail, "invalid_proof")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: WorldIDError.Equatable

    func test_world_id_error_equality_already_verified() {
        XCTAssertEqual(WorldIDError.alreadyVerified, WorldIDError.alreadyVerified)
    }

    func test_world_id_error_equality_proof_invalid() {
        XCTAssertEqual(
            WorldIDError.proofInvalid(detail: "x"),
            WorldIDError.proofInvalid(detail: "x")
        )
        XCTAssertNotEqual(
            WorldIDError.proofInvalid(detail: "x"),
            WorldIDError.proofInvalid(detail: "y")
        )
    }

    func test_world_id_error_equality_http_error() {
        XCTAssertEqual(
            WorldIDError.httpError(statusCode: 500, body: "a"),
            WorldIDError.httpError(statusCode: 500, body: "b")
        )
        XCTAssertNotEqual(
            WorldIDError.httpError(statusCode: 400, body: ""),
            WorldIDError.httpError(statusCode: 500, body: "")
        )
    }
}
