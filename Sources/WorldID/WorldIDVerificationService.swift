import Foundation

/// Concrete ``WorldIDVerifier`` that calls the World ID developer-portal API.
///
/// API reference: https://docs.worldcoin.org/reference/api
public struct WorldIDVerificationService: WorldIDVerifier {

    private static let baseURL = URL(string: "https://developer.worldcoin.org/api/v2/verify/")!

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: WorldIDVerifier

    public func verify(
        proof: WorldIDProof,
        appID: String,
        action: String,
        signal: String
    ) async throws -> String {
        let url = Self.baseURL.appendingPathComponent(appID)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = VerifyRequestBody(
            nullifierHash: proof.nullifierHash,
            merkleRoot: proof.merkleRoot,
            proof: proof.proof,
            verificationLevel: proof.verificationLevel.rawValue,
            action: action,
            signal: signal.isEmpty ? nil : signal
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await performRequest(request)

        guard let http = response as? HTTPURLResponse else {
            throw WorldIDError.httpError(statusCode: 0, body: "")
        }

        switch http.statusCode {
        case 200:
            return try decodeSuccess(data)
        case 400:
            let detail = (try? decodeErrorDetail(data)) ?? "bad_request"
            if detail.contains("already_used") || detail.contains("nullifier") {
                throw WorldIDError.alreadyVerified
            }
            throw WorldIDError.proofInvalid(detail: detail)
        default:
            let body = String(decoding: data, as: UTF8.self)
            throw WorldIDError.httpError(statusCode: http.statusCode, body: body)
        }
    }

    // MARK: Private helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw WorldIDError.networkFailure(urlError)
        }
    }

    private func decodeSuccess(_ data: Data) throws -> String {
        struct SuccessBody: Decodable {
            let nullifierHash: String
            private enum CodingKeys: String, CodingKey {
                case nullifierHash = "nullifier_hash"
            }
        }
        do {
            return try JSONDecoder().decode(SuccessBody.self, from: data).nullifierHash
        } catch {
            throw WorldIDError.decodingFailed(error.localizedDescription)
        }
    }

    private func decodeErrorDetail(_ data: Data) throws -> String {
        struct ErrorBody: Decodable {
            let code: String?
            let detail: String?
        }
        let body = try JSONDecoder().decode(ErrorBody.self, from: data)
        return body.code ?? body.detail ?? "unknown"
    }
}

// MARK: - Request body

private struct VerifyRequestBody: Encodable {
    let nullifierHash: String
    let merkleRoot: String
    let proof: String
    let verificationLevel: String
    let action: String
    let signal: String?

    private enum CodingKeys: String, CodingKey {
        case nullifierHash    = "nullifier_hash"
        case merkleRoot       = "merkle_root"
        case proof
        case verificationLevel = "verification_level"
        case action
        case signal
    }
}
