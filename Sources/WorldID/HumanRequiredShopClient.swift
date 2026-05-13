import Foundation

/// Represents a product available at humanrequired.shop.
public struct ShopProduct: Equatable, Sendable, Codable {
    public let id: String
    public let name: String
    public let priceJPY: Int

    public init(id: String, name: String, priceJPY: Int) {
        self.id = id
        self.name = name
        self.priceJPY = priceJPY
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case priceJPY = "price_jpy"
    }
}

/// Result of a successful World-ID-gated purchase.
public struct PurchaseReceipt: Equatable, Sendable, Codable {
    public let orderId: String
    public let productId: String
    public let nullifierHash: String
    public let createdAt: Date

    public init(orderId: String, productId: String, nullifierHash: String, createdAt: Date) {
        self.orderId = orderId
        self.productId = productId
        self.nullifierHash = nullifierHash
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case orderId      = "order_id"
        case productId    = "product_id"
        case nullifierHash = "nullifier_hash"
        case createdAt    = "created_at"
    }
}

/// Performs a World-ID-verified purchase at humanrequired.shop.
///
/// Flow:
/// 1. Call ``purchase(productID:proof:)``
/// 2. The client first verifies the proof via ``WorldIDVerifier``
/// 3. On success, it submits the purchase order to the shop API with the
///    verified nullifier hash as proof of humanity.
///
/// - Note: ``worldIDAppID`` and ``worldIDAction`` must match the values
///   configured in the humanrequired.shop World ID developer portal app.
public struct HumanRequiredShopClient: Sendable {

    private static let shopBaseURL = URL(string: "https://humanrequired.shop/api/")!

    /// World ID app ID registered for humanrequired.shop.
    public let worldIDAppID: String
    /// World ID action identifier (e.g. `"purchase"`).
    public let worldIDAction: String

    private let verifier: any WorldIDVerifier
    private let session: URLSession

    public init(
        worldIDAppID: String,
        worldIDAction: String = "purchase",
        verifier: any WorldIDVerifier = WorldIDVerificationService(),
        session: URLSession = .shared
    ) {
        self.worldIDAppID = worldIDAppID
        self.worldIDAction = worldIDAction
        self.verifier = verifier
        self.session = session
    }

    /// Verifies the World ID proof and places an order for `productID`.
    ///
    /// - Parameters:
    ///   - productID: The shop's product identifier.
    ///   - proof:     The ``WorldIDProof`` obtained from the World App.
    /// - Returns: A ``PurchaseReceipt`` on success.
    /// - Throws: ``WorldIDError`` if verification fails, or a network /
    ///           decoding error if the shop API call fails.
    public func purchase(productID: String, proof: WorldIDProof) async throws -> PurchaseReceipt {
        // 1. Verify humanity — use productID as the signal to bind the proof
        //    to this specific purchase intent.
        let nullifierHash = try await verifier.verify(
            proof: proof,
            appID: worldIDAppID,
            action: worldIDAction,
            signal: productID
        )

        // 2. Submit order to the shop
        return try await submitOrder(productID: productID, nullifierHash: nullifierHash)
    }

    // MARK: Private

    private func submitOrder(productID: String, nullifierHash: String) async throws -> PurchaseReceipt {
        let url = Self.shopBaseURL.appendingPathComponent("orders")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct OrderBody: Encodable {
            let productId: String
            let nullifierHash: String
            private enum CodingKeys: String, CodingKey {
                case productId    = "product_id"
                case nullifierHash = "nullifier_hash"
            }
        }
        request.httpBody = try JSONEncoder().encode(OrderBody(productId: productID, nullifierHash: nullifierHash))

        let (data, response) = try await performRequest(request)
        guard let http = response as? HTTPURLResponse else {
            throw WorldIDError.httpError(statusCode: 0, body: "")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw WorldIDError.httpError(
                statusCode: http.statusCode,
                body: String(decoding: data, as: UTF8.self)
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(PurchaseReceipt.self, from: data)
        } catch {
            throw WorldIDError.decodingFailed(error.localizedDescription)
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw WorldIDError.networkFailure(urlError)
        }
    }
}
