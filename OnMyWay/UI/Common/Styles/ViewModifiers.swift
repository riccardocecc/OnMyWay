//
//  ViewModifiers.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

// MARK: - Card Style
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

extension View {
    /// Applica lo stile standard "Card" (sfondo, corner radius, ombra leggera).
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    /// Padding standard orizzontale per le schermate.
    func standardPadding() -> some View {
        self.padding(.horizontal, 24)
    }
}
