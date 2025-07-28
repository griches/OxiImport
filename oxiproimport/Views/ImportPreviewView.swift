//
//  ImportPreviewView.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import SwiftUI

struct ImportPreviewView: View {
    let readings: [BloodPressureReading]
    @ObservedObject var healthKitManager: HealthKitManager
    let onImportComplete: (Bool, String) -> Void
    
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if isImporting {
                    importingView
                } else {
                    previewContent
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        startImport()
                    }
                    .disabled(isImporting)
                }
            }
        }
    }
    
    private var previewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            summarySection
            
            Divider()
            
            readingsList
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("\(readings.count) readings to import", systemImage: "doc.text.fill")
                .font(.headline)
            
            if let firstDate = readings.last?.date,
               let lastDate = readings.first?.date {
                Label(dateRangeText(from: firstDate, to: lastDate), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let avgSystolic = averageSystolic,
               let avgDiastolic = averageDiastolic {
                Label("Average: \(Int(avgSystolic))/\(Int(avgDiastolic)) mmHg", systemImage: "heart.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var readingsList: some View {
        List(readings) { reading in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.dateTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Text(reading.bloodPressureString)
                            .font(.headline)
                        
                        if let _ = reading.pulse {
                            Text(reading.pulseString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if reading.irregularPulseDetected {
                    Image(systemName: "waveform.path.ecg.rectangle")
                        .foregroundColor(.orange)
                        .imageScale(.small)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(PlainListStyle())
    }
    
    private var importingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Importing to Apple Health")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: importProgress) {
                Text("\(Int(importProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .progressViewStyle(LinearProgressViewStyle())
            .padding(.horizontal, 40)
            
            Text("\(Int(importProgress * Double(readings.count))) of \(readings.count) readings imported")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private var averageSystolic: Double? {
        guard !readings.isEmpty else { return nil }
        let sum = readings.reduce(0) { $0 + $1.systolic }
        return Double(sum) / Double(readings.count)
    }
    
    private var averageDiastolic: Double? {
        guard !readings.isEmpty else { return nil }
        let sum = readings.reduce(0) { $0 + $1.diastolic }
        return Double(sum) / Double(readings.count)
    }
    
    private func dateRangeText(from startDate: Date, to endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func startImport() {
        isImporting = true
        importProgress = 0
        
        Task {
            do {
                try await healthKitManager.saveMultipleReadings(readings) { progress in
                    importProgress = progress
                }
                
                await MainActor.run {
                    onImportComplete(true, "Successfully imported \(readings.count) readings to Apple Health")
                }
            } catch {
                await MainActor.run {
                    onImportComplete(false, "Import failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    ImportPreviewView(
        readings: [
            BloodPressureReading(
                date: Date(),
                systolic: 120,
                diastolic: 80,
                pulse: 72,
                irregularPulseDetected: false,
                source: "OxiPro BP2"
            )
        ],
        healthKitManager: HealthKitManager(),
        onImportComplete: { _, _ in }
    )
}