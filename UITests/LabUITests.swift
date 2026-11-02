import XCTest
import StoreKitTest

final class LabUITests: XCTestCase {
    private var session: SKTestSession!
    private var app: XCUIApplication!
    private let productID = "dev.pquanghuy.storekitlab.pro"

    override func setUpWithError() throws {
        continueAfterFailure = false
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["purchase"].waitForExistence(timeout: 15))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["purchase"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
    }

    override func tearDownWithError() throws {
        app?.terminate()
        session?.clearTransactions()
        session?.resetToDefaultState()
    }

    func testPurchaseRelaunchRestoreAndRefund() throws {
        app.buttons["purchase"].tap()
        XCTAssertTrue(app.staticTexts["proContent"].waitForExistence(timeout: 15))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "pro-unlocked"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["proContent"].waitForExistence(timeout: 15))
        app.buttons["restore"].tap()
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Pro access restored."), object: app.staticTexts["storeMessage"])
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 15), .completed)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        XCTAssertTrue(app.buttons["purchase"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["proContent"].exists)
    }

    func testAskToBuyDoesNotUnlockBeforeApproval() throws {
        session.askToBuyEnabled = true
        app.buttons["purchase"].tap()
        let pending = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Awaiting approval"), object: app.staticTexts["storeMessage"])
        XCTAssertEqual(XCTWaiter.wait(for: [pending], timeout: 15), .completed)
        XCTAssertFalse(app.staticTexts["proContent"].exists)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: transaction.identifier)
        XCTAssertTrue(app.staticTexts["proContent"].waitForExistence(timeout: 15))
    }
}
