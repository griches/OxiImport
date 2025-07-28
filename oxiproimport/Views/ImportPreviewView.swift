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
        NavigationStack {
            VStack {
                if isImporting {
                    importingView
                } else {
                    previewContent
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        startImport()
                    }
                    .disabled(isImporting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var previewContent: some View {
        VStack(spacing: 0) {
            summarySection
            readingsList
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary.opacity(0.8))
                    .frame(width: 24)
                Text("\(readings.count) readings to import")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if let firstDate = readings.last?.date,
               let lastDate = readings.first?.date {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.primary.opacity(0.8))
                        .frame(width: 24)
                    Text(dateRangeText(from: firstDate, to: lastDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            if let avgSystolic = averageSystolic,
               let avgDiastolic = averageDiastolic {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 24)
                    Text("Average: \(Int(avgSystolic))/\(Int(avgDiastolic)) mmHg")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
    }
    
    private var readingsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(readings) { reading in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(reading.dateTimeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    Text(reading.bloodPressureString)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    if let _ = reading.pulse {
                                        Text(reading.pulseString)
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if reading.irregularPulseDetected {
                                Image(systemName: "waveform.path.ecg.rectangle")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        if reading.id != readings.last?.id {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var importingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse)
                
                Text("Importing to Apple Health")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    ProgressView(value: importProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 1.5)
                    
                    Text("\(Int(importProgress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 60)
                
                Text("\(Int(importProgress * Double(readings.count))) of \(readings.count) readings imported")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
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