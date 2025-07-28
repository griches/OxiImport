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
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .padding(.top, 20)
                
                Text("HealthKit Access Required")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("This app needs permission to save blood pressure and heart rate data to Apple Health.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .frame(width: 20)
                    Text("Blood Pressure (Systolic/Diastolic)")
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Heart Rate")
                        .foregroundColor(.primary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .foregroundColor(.orange)
                        .frame(width: 20)
                    Text("Irregular Rhythm Notifications")
                        .foregroundColor(.primary)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            
            Button(action: requestAuthorization) {
                HStack(spacing: 12) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                        Text("Grant Access")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundColor(.white)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .disabled(isRequesting)
            .cornerRadius(12)
            
            Text("You can change permissions at any time in Settings > Privacy & Security > Health")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(24)
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