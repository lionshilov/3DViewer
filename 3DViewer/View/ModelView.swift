//
//  Model.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct ModelView: View {
    @StateObject private var viewModel = ModelViewModel()
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationView {
            VStack {
                // Добавлено описание приложения
                Text("3DViewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Загрузите и просматривайте 3D модели в форматах OBJ и STL. Вы можете вращать, увеличивать и уменьшать модели, чтобы изучать их детали с любого ракурса.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)

                Spacer()

                if let scene = viewModel.scene {
                    SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .padding(.horizontal)
                } else {
                    Text("Загрузите модель")
                        .foregroundColor(.gray)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .padding()
                }

                Spacer()

                Button(action: {
                    self.showDocumentPicker = true
                }) {
                    Text("Загрузить модель")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .fullScreenCover(isPresented: $showDocumentPicker) {
                    if let objType = UTType(filenameExtension: "obj"),
                       let stlType = UTType(filenameExtension: "stl") {
                        DocumentPicker(fileTypes: [objType, stlType], onDocumentPicked: { url in
                            viewModel.loadModel(url: url)
                        })
                    } else {
                        Text("Ошибка: не удалось загрузить допустимые типы файлов.")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Spacer()  // Добавление дополнительного пространства внизу
            }
            .navigationBarHidden(true)
        }
    }
}


