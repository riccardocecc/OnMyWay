//
//  DesignTypography.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

extension Font {
    // MARK: - Custom Typography
    
    /// Titoli grandi (es. Onboarding, Home Header).
    static let appLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    
    /// Titoli di sezione.
    static let appTitle = Font.system(.title2, design: .rounded).weight(.semibold)
    
    /// Testo in evidenza (es. ETA, Distanza).
    static let appHeadline = Font.system(.headline, design: .rounded).weight(.medium)
    
    /// Testo normale del corpo.
    static let appBody = Font.system(.body, design: .rounded)
    
    /// Didascalie e note a piè di pagina.
    static let appCaption = Font.system(.caption, design: .rounded).weight(.medium)
    
    /// Numeri grandi per il codice di pairing o countdown.
    static let appMonospacedDigit = Font.system(.title, design: .monospaced).weight(.bold)
}
