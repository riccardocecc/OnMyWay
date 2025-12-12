//
//  ButtonStyles.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

// MARK: - Primary Action Button
/// Bottone principale grande, pieno, con gradiente (es. "Inizia Viaggio", "Continua").
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .font(.appHeadline)
                .foregroundStyle(.white)
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(LinearGradient.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .animation(.spring(duration: 0.2), value: configuration.isPressed)
        .shadow(color: .brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Secondary Action Button
/// Bottone secondario, outline o sfondo leggero (es. "Annulla", "Riprova").
struct SecondaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBody.weight(.medium))
            .foregroundStyle(isDestructive ? Color.red : Color.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.1)) // Sfondo grigio chiaro
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Circular Button (Start Trip)
/// Stile specifico per il bottone circolare gigante della Home.
struct CircularTripButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 220, height: 220)
            .background(
                Circle()
                    .fill(LinearGradient.brandGradient)
                    .shadow(color: .brandPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Extensions for easy usage
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryAction: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primaryAction(isLoading: Bool) -> PrimaryButtonStyle { PrimaryButtonStyle(isLoading: isLoading) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondaryAction: SecondaryButtonStyle { SecondaryButtonStyle() }
    static var destructiveAction: SecondaryButtonStyle { SecondaryButtonStyle(isDestructive: true) }
}

extension ButtonStyle where Self == CircularTripButtonStyle {
    static var circularTrip: CircularTripButtonStyle { CircularTripButtonStyle() }
}
