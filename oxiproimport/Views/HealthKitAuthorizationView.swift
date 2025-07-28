//
//  HealthKitAuthorizationView.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import SwiftUI
import HealthKit

struct HealthKitAuthorizationView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var isRequesting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("HealthKit Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This app needs permission to save blood pressure and heart rate data to Apple Health.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Blood Pressure (Systolic/Diastolic)", systemImage: "heart.fill")
                Label("Heart Rate", systemImage: "waveform.path.ecg")
                Label("Irregular Rhythm Notifications", systemImage: "waveform.path.ecg.rectangle")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: requestAuthorization) {
                if isRequesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Text("Grant Access")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .frame(width: 200)
            
            Text("You can change permissions at any time in Settings > Privacy & Security > Health")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .alert("Authorization Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func requestAuthorization() {
        isRequesting = true
        
        Task {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isRequesting = false
                }
            }
        }
    }
}

#Preview {
    HealthKitAuthorizationView(healthKitManager: HealthKitManager())
}