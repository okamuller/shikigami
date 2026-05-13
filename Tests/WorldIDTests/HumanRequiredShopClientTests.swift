import XCTest
@testable import WorldID

final class HumanRequiredShopClientTests: XCTestCase {

    private let sampleProof = WorldIDProof(
        merkleRoot: "0xroot",
        nullifierHash: "0xnull",
        proof: "0xproof",
        verificationLevel: .orb
    )

    // MARK: - Purchase success path (stub verifier + mock URLSession)

    func test_purchase_passes_productID_as_signal_to_verifier() async throws {
        let captureStub = CapturingVerifier()
        captureStub.result = .success("0xnull")

        // Provide a URLSession that returns a valid shop receipt so the full
        // code path can be exercised without network access.
        let receiptJSON = """
        {
          "order_id": "ord_001",
          "product_id": "prod_abc",
          "nullifier_hash": "0xnull",
          "created_at": "2026-05-13T00:00:00Z"
        }
        """.data(using: .utf8)!
        let session = MockURLSession(response: receiptJSON, statusCode: 200)

        let client = HumanRequiredShopClient(
            worldIDAppID: "app_test",
            worldIDAction: "purchase",
            verifier: captureStub,
            session: session.urlSession
        )

        _ = try await client.purchase(productID: "prod_abc", proof: sampleProof)

        XCTAssertEqual(captureStub.capturedSignal, "prod_abc")
        XCTAssertEqual(captureStub.capturedAction, "purchase")
        XCTAssertEqual(captureStub.capturedAppID,  "app_test")
    }

    func test_purchase_propagates_already_verified_error() async {
        let stub = StubWorldIDVerifier()
        stub.result = .failure(.alreadyVerified)

        let client = HumanRequiredShopClient(
            worldIDAppID: "app_test",
            worldIDAction: "purchase",
            verifier: stub
        )

        do {
            _ = try await client.purchase(productID: "prod_abc", proof: sampleProof)
            XCTFail("Expected error")
        } catch WorldIDError.alreadyVerified {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_shop_api_non_2xx_throws_http_error() async throws {
        let stub = StubWorldIDVerifier()
        stub.result = .success("0xnull")

        let session = MockURLSession(response: Data(), statusCode: 422)
        let client = HumanRequiredShopClient(
            worldIDAppID: "app_test",
            verifier: stub,
            session: session.urlSession
        )

        do {
            _ = try await client.purchase(productID: "prod_abc", proof: sampleProof)
            XCTFail("Expected httpError")
        } catch WorldIDError.httpError(let code, _) {
            XCTAssertEqual(code, 422)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test helpers

/// Verifier that records the last call arguments.
final class CapturingVerifier: WorldIDVerifier, @unchecked Sendable {
    var result: Result<String, WorldIDError> = .success("0xhash")
    private(set) var capturedSignal: String?
    private(set) var capturedAction: String?
    private(set) var capturedAppID: String?

    func verify(
        proof: WorldIDProof,
        appID: String,
        action: String,
        signal: String
    ) async throws -> String {
        capturedSignal = signal
        capturedAction = action
        capturedAppID  = appID
        switch result {
        case .success(let h): return h
        case .failure(let e): throw e
        }
    }
}

/// Minimal URLSession mock backed by URLProtocol.
final class MockURLSession: @unchecked Sendable {
    let urlSession: URLSession

    init(response: Data, statusCode: Int) {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: config)
        MockURLProtocol.stubbedData       = response
        MockURLProtocol.stubbedStatusCode = statusCode
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var stubbedData: Data = Data()
    static var stubbedStatusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubbedStatusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubbedData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
