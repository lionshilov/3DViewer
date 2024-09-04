//
//  ModelViewModel.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import Foundation
import Combine
import SceneKit
import ModelIO

class ModelViewModel: ObservableObject {
    @Published var scene: SCNScene?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadModel(url: URL) {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .background).async {
            // Load the 3D model using ModelIO
            let asset = MDLAsset(url: url)
            asset.loadTextures()

            // Convert the first object in the asset to a mesh if possible
            guard let mdlMesh = asset.object(at: 0) as? MDLMesh else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load model or model is not a valid mesh."
                    self.isLoading = false
                }
                return
            }

            // Create SceneKit geometry from the MDLMesh
            let vertexBuffer = mdlMesh.vertexBuffers[0]
            let vertexCount = mdlMesh.vertexCount
            let vertexData = vertexBuffer.map().bytes.bindMemory(to: Float.self, capacity: vertexBuffer.length / MemoryLayout<Float>.size)
            
            let positionSource = SCNGeometrySource(
                data: Data(bytes: vertexData, count: vertexBuffer.length),
                semantic: .vertex,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 3
            )

            var geometryElements = [SCNGeometryElement]()

            for submesh in mdlMesh.submeshes as! [MDLSubmesh] {
                let indexBuffer = submesh.indexBuffer
                let indexData = indexBuffer.map().bytes.bindMemory(to: UInt32.self, capacity: indexBuffer.length / MemoryLayout<UInt32>.size)
                
                let geometryElement = SCNGeometryElement(
                    data: Data(bytes: indexData, count: indexBuffer.length),
                    primitiveType: .triangles,
                    primitiveCount: submesh.indexCount / 3,
                    bytesPerIndex: MemoryLayout<UInt32>.size
                )

                geometryElements.append(geometryElement)
            }

            let geometry = SCNGeometry(sources: [positionSource], elements: geometryElements)
            let node = SCNNode(geometry: geometry)
            let scene = SCNScene()
            scene.rootNode.addChildNode(node)

            DispatchQueue.main.async {
                self.scene = scene
                self.isLoading = false
            }
        }
    }
}
