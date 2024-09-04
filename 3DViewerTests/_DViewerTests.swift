//
//  _DViewerTests.swift
//  3DViewerTests
//
//  Created by Лев Шилов on 04.09.2024.
//

import XCTest
import SceneKit
@testable import _DViewer

final class ModelViewModelTests: XCTestCase {
    
    var viewModel: ModelViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ModelViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testLoadModel() {
        let expectation = XCTestExpectation(description: "Load Model")
        let testURL = Bundle.main.url(forResource: "testModel", withExtension: "obj")!
        
        viewModel.loadModel(url: testURL)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNotNil(self.viewModel.scene, "Model should be loaded and scene should not be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }

    func testUpdateModel() {
        let testURL = Bundle.main.url(forResource: "testModel", withExtension: "obj")!
        viewModel.updateModel(url: testURL)
        
        XCTAssertEqual(viewModel.modelData.url, testURL, "ModelData URL should be updated")
    }
}
