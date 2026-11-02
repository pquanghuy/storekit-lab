import SwiftUI
import StoreKit

@main
struct StoreKitLabApp: App {
    @StateObject private var store = StoreModel()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Label("STOREKIT 2 · LOCAL DEMO", systemImage: "shippingbox")
                            .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: store.hasPro ? "lock.open.fill" : "sparkles")
                                .font(.largeTitle).foregroundStyle(.indigo)
                            Text(store.hasPro ? "Your Pro workspace" : "A little more possibility.")
                                .font(.largeTitle.bold())
                            Text("One purchase. A workspace that stays yours.")
                                .foregroundStyle(.secondary)
                            Label(store.hasPro ? "Pro unlocked" : "Free access", systemImage: store.hasPro ? "checkmark.seal.fill" : "lock.fill")
                                .font(.headline).accessibilityIdentifier("accessStatus")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24).background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Pro Unlock").font(.title2.bold())
                            Label("Entitlement-gated sample content", systemImage: "note.text")
                            Label("Access restored across launches", systemImage: "rectangle.and.pencil.and.ellipsis")
                            Text("Demo content • One-time purchase • No subscription")
                                .font(.caption).foregroundStyle(.secondary)
                            if store.hasPro {
                                Text("Welcome to Pro. This sample workspace demonstrates entitlement-gated content.")
                                    .padding().background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                    .accessibilityIdentifier("proContent")
                            } else {
                                Button { Task { await store.purchase() } } label: {
                                    Text(store.product.map { "Unlock Pro · \($0.displayPrice)" } ?? "Store unavailable")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent).tint(.indigo)
                                .disabled(store.product == nil || store.busy)
                                .accessibilityIdentifier("purchase")
                            }
                            HStack {
                                Button("Restore purchases") { Task { await store.restore() } }
                                    .accessibilityIdentifier("restore")
                                Spacer()
                                Button("Reload") { Task { await store.load() } }
                            }.disabled(store.busy)
                            if store.busy { ProgressView() }
                            Text(store.message).font(.footnote).foregroundStyle(.secondary)
                                .accessibilityIdentifier("storeMessage")
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Transaction journal").font(.headline)
                            if store.events.isEmpty {
                                Text("Purchase events will appear here.").foregroundStyle(.secondary)
                            }
                            ForEach(Array(store.events.enumerated()), id: \.offset) { _, event in
                                Label(event, systemImage: "circle.fill").font(.caption)
                            }
                        }
                        Text("Run with Products.storekit to use simulated purchases. No real payment is collected in local StoreKit testing.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(24)
                }.navigationTitle("StoreKit Lab")
            }.task { await store.load() }
                .onChange(of: phase) { _, value in
                    if value == .active { Task { await store.refresh() } }
                }
        }
    }
}
