import StoreKit
import SwiftUI

@MainActor
final class StoreModel: ObservableObject {
    static let productID = "dev.pquanghuy.storekitlab.pro"
    @Published private(set) var product: Product?
    @Published private(set) var hasPro = false
    @Published private(set) var busy = false
    @Published private(set) var message = "Checking purchases…"
    @Published private(set) var events: [String] = []
    private var listener: Task<Void, Never>?

    init() {
        listener = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.receive(result)
            }
        }
    }

    deinit { listener?.cancel() }

    func load() async {
        await refresh()
        do {
            product = try await Product.products(for: [Self.productID]).first
            message = product == nil ? "Product unavailable. Check the StoreKit configuration." : "Ready"
        } catch {
            message = "Could not load the store. Please retry."
            log("Product loading failed")
        }
    }

    func refresh() async {
        var entitled = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                entitled = true
            }
        }
        hasPro = entitled
    }

    func purchase() async {
        guard !busy, let product else { return }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result): await receive(result)
            case .pending:
                message = "Awaiting approval. Access stays locked until verified."
                log("Purchase pending")
            case .userCancelled:
                message = "Purchase cancelled. You can try again anytime."
                log("Purchase cancelled")
            @unknown default:
                message = "Unknown purchase state. Please try again."
            }
        } catch {
            message = "Purchase failed. Please try again."
            log("Purchase failed")
        }
    }

    func restore() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refresh()
            message = hasPro ? "Pro access restored." : "No Pro purchase found."
            log("Restore completed")
        } catch {
            message = "Restore did not complete. Please try again."
            log("Restore failed or cancelled")
        }
    }

    private func receive(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else {
            message = "Transaction could not be verified. Access was not granted."
            log("Rejected unverified transaction")
            return
        }
        guard transaction.productID == Self.productID else { return }
        // Rebuild access from StoreKit rather than a persisted Boolean.
        await refresh()
        message = hasPro ? "Pro is unlocked." : "Pro access is no longer active."
        log(transaction.revocationDate == nil ? "Verified transaction received" : "Purchase revoked")
        // Content access has been updated before acknowledging delivery.
        await transaction.finish()
        log("Transaction finished")
    }

    private func log(_ event: String) {
        events.insert(event, at: 0)
        events = Array(events.prefix(20))
    }
}
