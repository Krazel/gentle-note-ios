import StoreKit

@MainActor
final class SupportStore: ObservableObject {
    static let productIDs = [
        "com.krazel.gentlenote.support.small",
        "com.krazel.gentlenote.support.kind",
        "com.krazel.gentlenote.support.sustaining"
    ]
    @Published var products: [Product] = []
    @Published var message: String?

    func load() async {
        do { products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price } }
        catch { message = "Support options are not available right now.".gentleLocalized }
    }

    func purchase(_ product: Product) async {
        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                message = "Thank you. Your support helps with maintenance and future updates.".gentleLocalized
            case .pending: message = "The purchase is pending with Apple.".gentleLocalized
            case .userCancelled: message = nil
            @unknown default: message = "Support wasn’t completed.".gentleLocalized
            }
        } catch { message = "The purchase was not completed. You can try again later.".gentleLocalized }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw SupportPurchaseError.failedVerification
        }
    }
}

enum SupportPurchaseError: Error { case failedVerification }

enum SupportConfiguration {
    // Keep false until the owner authorizes real App Store Connect products.
    static let isEnabled = false
}
