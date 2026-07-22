//
//  RestaurantMagnateUITests.swift
//  RestaurantMagnateUITests
//
//  Created by ilan on 7/18/26.
//

import XCTest

final class RestaurantMagnateUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testStartsPassAndPlayGameAndRolls() throws {
        let app = XCUIApplication()
        app.launch()
        rotateToLandscape(app)

        let gameTitle = app.descendants(matching: .any)["game-title"]
        XCTAssertTrue(gameTitle.waitForExistence(timeout: 5))

        let startButton = app.buttons["setup-start"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()

        let board = app.descendants(matching: .any)["board-grid"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Restaurant Magnate landscape game board on iPhone 13"
        attachment.lifetime = .keepAlways
        add(attachment)

        let rollButton = app.buttons["Roll Dice"]
        for _ in 0..<3 where !rollButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(rollButton.isHittable)
        rollButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["event-feed"].exists)
    }

    @MainActor
    func testFourPlayerSetupRemainsUsable() throws {
        let app = XCUIApplication()
        app.launch()
        rotateToLandscape(app)

        let fourPlayers = app.segmentedControls.buttons["4 PLAYERS"]
        XCTAssertTrue(fourPlayers.waitForExistence(timeout: 5))
        fourPlayers.tap()

        for index in 0..<4 {
            XCTAssertTrue(app.textFields["player-name-\(index)"].exists)
        }

        let startButton = app.buttons["setup-start"]
        for _ in 0..<3 where !startButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(startButton.isHittable)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Restaurant Magnate four player setup on iPhone 13"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func rotateToLandscape(_ app: XCUIApplication) {
        XCUIDevice.shared.orientation = .landscapeLeft
        let window = app.windows.firstMatch
        let landscapeWindow = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let element = object as? XCUIElement else {
                    return false
                }
                return element.exists && element.frame.width > element.frame.height
            },
            object: window
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [landscapeWindow], timeout: 5),
            .completed
        )
    }
}
