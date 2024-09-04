//
//  ModelData.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import Foundation
import SceneKit

struct ModelData {
    var url: URL
    var scene: SCNScene?
    var isLoading: Bool = false
    var errorMessage: String?
}
