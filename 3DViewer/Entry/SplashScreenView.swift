//
//  SplashScreenView.swift
//  3DViewer
//
//  Created by Лев Шилов on 04.09.2024.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        if isActive {
            ModelView()
        } else {
            VStack {
                Spacer() // Добавляем Spacer для центрирования контента по вертикали

                Text(NSLocalizedString("Welcome to 3DViewer!", comment: "Splash screen welcome message"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()

                Text(NSLocalizedString("Explore the world of 3D models. Load, convert, and enjoy models in various formats.", comment: "Splash screen description"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer() // Добавляем Spacer для центрирования контента по вертикали
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.scale = 1.0
                    self.opacity = 1.0
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}

