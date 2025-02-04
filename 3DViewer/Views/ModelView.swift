//
//  Model.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct ModelView: View {
    @StateObject private var viewModel = ModelViewModel()
    @State private var showDocumentPicker = false
    @State private var showConversionOptions = false
    @State private var conversionInProgress = false
    @State private var convertedModelURL: URL?

    var body: some View {
        NavigationView {
            VStack {
                // Описание приложения
                Text("3DViewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text(NSLocalizedString("Load and view 3D models in OBJ, STL, or FBX formats. Rotate, zoom, and pan the models to explore details from any angle.", comment: ""))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)

                Spacer()

                // Отображение SceneView, если модель загружена
                if let scene = viewModel.scene {
                    SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .padding(.horizontal)
                    
                    // Кнопка для конвертации модели
                    Button(action: {
                        showConversionOptions = true
                    }) {
                        Text(NSLocalizedString("Convert Model", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                } else {
                    // Текст-заполнитель, если модель не загружена
                    Text(NSLocalizedString("Load Model", comment: ""))
                        .foregroundColor(.gray)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .padding()
                }

                Spacer()

                // Кнопка загрузки модели
                Button(action: {
                    self.showDocumentPicker = true
                }) {
                    Text(NSLocalizedString("Load Model", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .fullScreenCover(isPresented: $showDocumentPicker) {
                    // Показать DocumentPicker для выбора файла модели
                    if let objType = UTType(filenameExtension: "obj"),
                       let stlType = UTType(filenameExtension: "stl"),
                       let fbxType = UTType(filenameExtension: "fbx"),
                       let plyType = UTType(filenameExtension: "ply"),
                       let usdzType = UTType(filenameExtension: "usdz") {
                        DocumentPicker(fileTypes: [objType, stlType, fbxType, plyType, usdzType], onDocumentPicked: { url in
                            viewModel.loadModel(url: url)
                        })
                    } else {
                        Text(NSLocalizedString("Error: Unable to load supported file types.", comment: ""))
                            .foregroundColor(.red)
                            .padding()
                    }
                }

                Spacer()  // Добавляет дополнительное пространство внизу

            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showConversionOptions) {
                // Открывает экран с опциями конвертации модели
                ConversionOptionsView(viewModel: viewModel, conversionInProgress: $conversionInProgress, convertedModelURL: $convertedModelURL)
            }
            .alert(isPresented: $viewModel.isShowingError) {
                // Отображение алерта при ошибке
                Alert(title: Text(NSLocalizedString("Error", comment: "")), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct ConversionOptionsView: View {
    @ObservedObject var viewModel: ModelViewModel
    @Binding var conversionInProgress: Bool
    @Binding var convertedModelURL: URL?

    var body: some View {
        VStack {
            Text(NSLocalizedString("Choose a format to convert", comment: ""))
                .font(.headline)
                .padding()

            // Кнопки для различных форматов конвертации
            Button(action: {
                convertModel(to: "stl")
            }) {
                Text(NSLocalizedString("Convert to STL", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button(action: {
                convertModel(to: "obj")
            }) {
                Text(NSLocalizedString("Convert to OBJ", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button(action: {
                convertModel(to: "ply")
            }) {
                Text(NSLocalizedString("Convert to PLY", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()

            // Показать индикатор прогресса при конвертации
            if conversionInProgress {
                ProgressView(NSLocalizedString("Conversion in progress...", comment: ""))
                    .padding()
            } else if let url = convertedModelURL {
                // Сообщение о успешной конвертации
                Text(NSLocalizedString("Model successfully converted!", comment: ""))
                    .foregroundColor(.green)
                    .padding()

                // Кнопка для открытия меню общего доступа или сохранения модели
                Button(action: {
                    shareConvertedModel(url: url)
                }) {
                    Text(NSLocalizedString("Share or save model", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
    }

    // Функция для конвертации модели в заданный формат
    private func convertModel(to format: String) {
        conversionInProgress = true
        viewModel.convertModel(to: format) { url in
            conversionInProgress = false
            convertedModelURL = url
        }
    }

    // Функция для открытия меню общего доступа или сохранения сконвертированной модели
    private func shareConvertedModel(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let presentedVC = rootViewController.presentedViewController {
            presentedVC.dismiss(animated: true) {
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        } else {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
