//
//  PairingView.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

struct PairingView: View {
    @Environment(AppState.self) private var appState
    // Usiamo il manager dal container
    private var pairingManager: PairingManager { appState.pairingManager }
    
    @State private var selectedTab = 0
    @State private var generatedCode: String?
    @State private var inputCode: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Connessione Partner")
                .font(.appLargeTitle)
                .padding(.top, 40)
            
            Text("Per iniziare, tu e il tuo partner dovete collegarvi.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Picker
            Picker("Modalità", selection: $selectedTab) {
                Text("Genera Codice").tag(0)
                Text("Inserisci Codice").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .padding(.top, 20)
            
            // Content
            TabView(selection: $selectedTab) {
                generateCodeView
                    .tag(0)
                
                enterCodeView
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Logout button (sempre utile se si sbaglia account)
            Button("Cambia Account") {
                appState.signOut()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .font(.caption)
            .padding(.bottom, 20)
        }
        .background(Color.brandBackground.ignoresSafeArea())
        .alert(item: Binding<AppError?>(
            get: { errorMessage.map { .pairing($0) } },
            set: { _ in errorMessage = nil }
        )) { error in
            Alert(title: Text("Errore"), message: Text(error.errorDescription ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Tab 1: Genera Codice
    var generateCodeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if let code = generatedCode {
                VStack(spacing: 10) {
                    Text(code)
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .tracking(8) // Spaziatura tra numeri
                        .foregroundStyle(Color.brandPrimary)
                    
                    Text("Condividi questo codice con il partner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Scade tra 5 minuti")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 100))
                    .foregroundStyle(.gray.opacity(0.3))
                
                Text("Tocca il bottone per generare un codice univoco.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                Task {
                    await generateCode()
                }
            } label: {
                Text(generatedCode == nil ? "Genera Codice" : "Genera Nuovo Codice")
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: isProcessing))
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Tab 2: Inserisci Codice
    var enterCodeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Inserisci il codice del partner")
                    .font(.headline)
                
                TextField("123456", text: $inputCode)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brandPrimary.opacity(0.5), lineWidth: 1)
                    )
                    .frame(maxWidth: 250)
                    .onChange(of: inputCode) { _, newValue in
                        // Limita a 6 caratteri
                        if newValue.count > 6 {
                            inputCode = String(newValue.prefix(6))
                        }
                    }
            }
            
            Spacer()
            
            Button {
                Task {
                    await submitCode()
                }
            } label: {
                Text("Collega Partner")
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: isProcessing))
            .disabled(inputCode.count != 6)
            .opacity(inputCode.count == 6 ? 1 : 0.6)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Logic
    
    func generateCode() async {
        isProcessing = true
        errorMessage = nil
        do {
            let code = try await pairingManager.generatePairingCode()
            withAnimation {
                self.generatedCode = code
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    
    func submitCode() async {
        isProcessing = true
        errorMessage = nil
        
        // Chiudi tastiera
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        do {
            try await pairingManager.pairWith(code: inputCode)
            // Successo! Non serve navigare manualmente.
            // Il listener su Firestore rileverà la modifica in 'currentUser'
            // AppState aggiornerà 'isPaired' -> AppRouter mostrerà la Home.
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}
