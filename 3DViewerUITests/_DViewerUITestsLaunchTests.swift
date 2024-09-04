//
//  _DViewerUITestsLaunchTests.swift
//  3DViewerUITests
//
//  Created by Лев Шилов on 04.09.2024.
//

import XCTest

final class _DViewerUITestsLaunchTests: XCTestCase {

    // This property determines whether the test method runs for each app UI configuration
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    // Setup method to configure the test environment
    override func setUpWithError() throws {
        // Continue testing even if a failure occurs
        continueAfterFailure = false
    }

    // Test method to verify app launch
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert additional steps here if needed, such as logging into a test account
        // or navigating somewhere in the app to set up the desired state before taking a screenshot.

        // Take a screenshot after the app has launched
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
