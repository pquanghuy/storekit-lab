# Reliable access after a purchase

## Problem

A successful purchase button is only one part of in-app purchases. A transaction can await approval, arrive outside the purchase call, or be refunded after content was unlocked. A cached `isPro` flag can diverge from the store.

## Approach

`StoreModel` is the main-actor source of UI state. It observes StoreKit updates from initialization, loads the product, and reconstructs access from verified current entitlements. The UI has no separate purchase authority.

Both direct purchase results and background updates enter the same verified transaction handler. Only the known product is handled. It refreshes access before finishing the transaction. Unverified transactions are rejected and left unfinished; no content is granted from their payload.

The app refreshes access when becoming active, so returning from another flow doesn't rely solely on an in-memory purchase state. Restore is an explicit action rather than an automatic sign-in prompt on every launch.

## Tradeoffs

A single non-consumable makes the entitlement rule small and inspectable. There is no subscription expiration, grace period, consumable balance, or backend delivery to model. Production apps that deliver server-side content require server-side authorization and additional recovery mechanisms.

The journal is capped at 20 entries and contains generic events rather than transaction IDs or signed payloads. It resets when the app exits.

## Evidence

The UI tests use Apple's StoreKitTest environment to verify visible access across purchase, relaunch, restore, refund, and deferred approval. See VALIDATION.md for the tested environment and remaining manual scenarios. No performance or production reliability metrics are claimed.
