# Validation

Executed on 2026-11-02 with Xcode 27.0, an iPhone 18 Pro simulator, and iOS 27.0.

**Result: 2 UI integration tests passed, 0 failures.** These exercise the actual app and Apple's local StoreKit service, not a fake purchase provider.

| Scenario | Observed result |
| --- | --- |
| Buy configured non-consumable | Pro content becomes visible |
| Relaunch after purchase | Pro content remains available |
| Explicit restore | App reports Pro access restored |
| Refund through StoreKitTest | Purchase button returns; Pro content disappears |
| Ask to Buy pending | Pro content stays unavailable |
| Approve pending transaction | Listener unlocks Pro content |

Command (replace the destination with an available simulator):

```sh
xcodebuild -project StoreKitLab.xcodeproj -scheme StoreKitLab \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

Initial test runs exposed missing configuration in the test bundle and missing StoreKit configuration in the Test action. Both were corrected before the successful run. The shared scheme now configures both Run and Test.

`images/pro-unlocked.png` is an unedited XCTest attachment from the passing purchase test.

## Not yet verified

- User dismissal of the system purchase sheet (automated tests disable dialogs).
- Forced network/store failure, unverified transaction injection, and restore with no purchases.
- Physical device, App Store sandbox/TestFlight, and production transactions.
- GitHub Actions execution; a workflow is supplied but has not run remotely.

These cases are not included in the passing-test count.
