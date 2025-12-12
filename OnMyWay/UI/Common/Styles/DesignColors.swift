//
//  DesignColors.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

extension Color {
    // MARK: - Brand Identity
    /// Il colore principale (Safety Blue/Indigo). Ispira fiducia e calma.
    static let brandPrimary = Color.indigo
    
    /// Colore secondario per accenti e dettagli (Teal/Cyan).
    static let brandSecondary = Color.cyan
    
    /// Colore di sfondo per le schermate principali (leggermente off-white in light mode).
    static let brandBackground = Color(uiColor: .systemGroupedBackground)
    
    /// Colore per le card e i contenitori in primo piano.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    
    // MARK: - Status Indicators
    /// Indica che il viaggio è attivo e connesso.
    static let statusActive = Color.blue
    
    /// Indica che il partner è arrivato a casa (Successo).
    static let statusArrived = Color.green
    
    /// Indica un problema o stato offline (Attenzione).
    static let statusWarning = Color.orange
    
    /// Indica un errore critico o viaggio cancellato.
    static let statusError = Color.red
    
    /// Colore neutro per placeholder o stati in attesa.
    static let neutralGray = Color.gray.opacity(0.3)
}

extension ShapeStyle where Self == LinearGradient {
    // MARK: - Gradients
    
    /// Gradiente principale per il bottone "Torno a Casa" e header.
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [.indigo, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradiente animato per lo stato di viaggio attivo.
    static var tripActiveGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .cyan],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
