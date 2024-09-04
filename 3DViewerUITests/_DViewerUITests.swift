//
//  _DViewerUITests.swift
//  3DViewerUITests
//
//  Created by Лев Шилов on 04.09.2024.
//

import XCTest

final class ModelViewUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDocumentPickerOpens() throws {
        let app = XCUIApplication()
        app.launch()
        
        let loadModelButton = app.buttons["Загрузить модель"]
        XCTAssertTrue(loadModelButton.exists, "Load Model button should exist")
        loadModelButton.tap()
        
        let documentPicker = app.sheets.firstMatch
        XCTAssertTrue(documentPicker.waitForExistence(timeout: 3), "Document Picker should appear after tapping Load Model button")
    }
}
