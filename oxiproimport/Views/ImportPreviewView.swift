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
    @State private var duplicateCheckResults: Set<ExistingReading>?
    @State private var isCheckingDuplicates = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if isImporting {
                    importingView
                } else if isCheckingDuplicates {
                    checkingDuplicatesView
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
                    .disabled(isImporting || isCheckingDuplicates)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        startImport()
                    }
                    .disabled(isImporting || isCheckingDuplicates || duplicatesCount == readings.count)
                    .fontWeight(.semibold)
                }
            }
            .task {
                await checkForDuplicates()
            }
        }
    }
    
    private var previewContent: some View {
        VStack(spacing: 0) {
            summarySection
            readingsList
        }
    }
    
    private var checkingDuplicatesView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Checking for duplicates...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var duplicatesCount: Int {
        guard let duplicateCheckResults = duplicateCheckResults else { return 0 }
        return readings.filter { reading in
            duplicateCheckResults.contains(ExistingReading(
                date: reading.date,
                systolic: reading.systolic,
                diastolic: reading.diastolic
            ))
        }.count
    }
    
    private var newReadingsCount: Int {
        readings.count - duplicatesCount
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primary.opacity(0.8))
                    .frame(width: 24)
                
                if let _ = duplicateCheckResults {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(newReadingsCount) new readings to import")
                            .font(.headline)
                            .foregroundColor(.primary)
                        if duplicatesCount > 0 {
                            Text("\(duplicatesCount) duplicates will be skipped")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    Text("\(readings.count) readings to import")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
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
                    let isDuplicate = duplicateCheckResults?.contains(ExistingReading(
                        date: reading.date,
                        systolic: reading.systolic,
                        diastolic: reading.diastolic
                    )) ?? false
                    
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(reading.dateTimeString)
                                    .font(.caption)
                                    .foregroundColor(isDuplicate ? .secondary.opacity(0.6) : .secondary)
                                
                                HStack(spacing: 16) {
                                    Text(reading.bloodPressureString)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(isDuplicate ? .primary.opacity(0.5) : .primary)
                                    
                                    if let _ = reading.pulse {
                                        Text(reading.pulseString)
                                            .font(.system(size: 16))
                                            .foregroundColor(isDuplicate ? .secondary.opacity(0.5) : .secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if isDuplicate {
                                Label("Duplicate", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if reading.irregularPulseDetected {
                                Image(systemName: "waveform.path.ecg.rectangle")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .opacity(isDuplicate ? 0.6 : 1.0)
                        
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
                let result = try await healthKitManager.saveMultipleReadings(readings) { progress in
                    importProgress = progress
                }
                
                await MainActor.run {
                    let message: String
                    if result.skipped > 0 {
                        message = "Successfully imported \(result.imported) new readings and skipped \(result.skipped) duplicates"
                    } else {
                        message = "Successfully imported \(result.imported) readings to Apple Health"
                    }
                    onImportComplete(true, message)
                }
            } catch {
                await MainActor.run {
                    onImportComplete(false, "Import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkForDuplicates() async {
        guard !readings.isEmpty else { return }
        
        isCheckingDuplicates = true
        
        do {
            let dates = readings.map { $0.date }
            if let startDate = dates.min(),
               let endDate = dates.max() {
                let queryStartDate = startDate.addingTimeInterval(-60)
                let queryEndDate = endDate.addingTimeInterval(60)
                
                duplicateCheckResults = try await healthKitManager.queryBloodPressureReadings(
                    from: queryStartDate,
                    to: queryEndDate
                )
            }
        } catch {
            // If we can't check for duplicates, proceed without the check
            print("Failed to check for duplicates: \(error)")
        }
        
        isCheckingDuplicates = false
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