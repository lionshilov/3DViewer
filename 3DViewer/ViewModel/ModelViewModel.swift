//
//  ModelViewModel.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import SceneKit
import ModelIO
import MetalKit

class ModelViewModel: ObservableObject {
    @Published var scene: SCNScene?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isShowingError: Bool = false
    
    func loadModel(url: URL) {
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .background).async {
            // Загружаем 3D модель с использованием ModelIO
            let asset = MDLAsset(url: url)
            asset.loadTextures()
            
            // Конвертируем первый объект в MDLMesh, если возможно
            guard let mdlMesh = asset.object(at: 0) as? MDLMesh else {
                DispatchQueue.main.async {
                    self.errorMessage = "Не удалось загрузить модель или модель не является допустимой сеткой."
                    self.isLoading = false
                    self.isShowingError = true
                }
                return
            }
            
            // Создаем SCNGeometry из MDLMesh
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
    
    func convertModel(to format: String, completion: @escaping (URL?) -> Void) {
        guard let scene = self.scene else {
            self.errorMessage = "Нет загруженной модели для конвертации."
            self.isShowingError = true
            completion(nil)
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        DispatchQueue.global(qos: .background).async {
            guard let device = MTLCreateSystemDefaultDevice() else {
                DispatchQueue.main.async {
                    self.errorMessage = "Metal не поддерживается на этом устройстве."
                    self.isLoading = false
                    self.isShowingError = true
                    completion(nil)
                }
                return
            }
            
            let allocator = MTKMeshBufferAllocator(device: device)
            let asset = MDLAsset(bufferAllocator: allocator)
            
            // Рекурсивная функция для добавления SCNNodes в MDLAsset
            func addNode(_ node: SCNNode) {
                if let geometry = node.geometry, let mdlMesh = self.createMDLMesh(from: geometry, device: device) {
                    asset.add(mdlMesh)
                }
                for child in node.childNodes {
                    addNode(child)
                }
            }
            
            // Добавляем все узлы из SCNScene в MDLAsset
            addNode(scene.rootNode)
            
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let convertedURL = documentsDirectory?.appendingPathComponent("convertedModel.\(format)")
            
            guard let saveURL = convertedURL else {
                DispatchQueue.main.async {
                    self.errorMessage = "Не удалось создать путь к файлу для конвертированной модели."
                    self.isLoading = false
                    self.isShowingError = true
                    completion(nil)
                }
                return
            }
            
            do {
                // Удаляем файл, если он уже существует
                if fileManager.fileExists(atPath: saveURL.path) {
                    try fileManager.removeItem(at: saveURL)
                }
                
                // Экспортируем модель в указанный формат
                switch format.lowercased() {
                case "obj", "stl", "ply":
                    
                    try asset.export(to: saveURL)
                    // TODO: Добавить FBX & USDZ Models
                    //                case "fbx":
                    //                    // Custom settings for FBX export
                    //                    try asset.export(to: saveURL)
                    //                case "usdz":
                    //                    // Ensure USDZ compatibility
                    //                    let usdzExporter = USDZExporter()
                    //                    try usdzExporter.export(asset, to: saveURL)
                default:
                    throw NSError(domain: "Unsupported format", code: -1, userInfo: nil)
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(saveURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to convert model: \(error.localizedDescription)"
                    self.isLoading = false
                    self.isShowingError = true
                    completion(nil)
                }
            }
        }
    }
    
    
    // Функция для создания MDLMesh из SCNGeometry
    func createMDLMesh(from scnGeometry: SCNGeometry, device: MTLDevice) -> MDLMesh? {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 3)
        
        guard let vertexSource = scnGeometry.sources(for: .vertex).first else {
            return nil
        }
        
        let vertexData = vertexSource.data
        let vertexCount = vertexSource.vectorCount
        
        guard let element = scnGeometry.elements.first else {
            return nil
        }
        
        let indexData = element.data
        let indexCount = element.primitiveCount * 3
        
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let vertexBuffer = allocator.newBuffer(with: vertexData, type: .vertex)
        let indexBuffer = allocator.newBuffer(with: indexData, type: .index)
        
        let submesh = MDLSubmesh(indexBuffer: indexBuffer,
                                 indexCount: indexCount,
                                 indexType: .uInt32,
                                 geometryType: .triangles,
                                 material: nil)
        
        let mdlMesh = MDLMesh(vertexBuffer: vertexBuffer,
                              vertexCount: vertexCount,
                              descriptor: vertexDescriptor,
                              submeshes: [submesh])
        
        return mdlMesh
    }
}
