//
//  ContentView.swift
//  oxiproimport
//
//  Created by Gary Riches on 28/07/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var historyManager = ImportHistoryManager()
    @EnvironmentObject var fileHandler: IncomingFileHandler
    @State private var showingImporter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var parsedReadings: [BloodPressureReading] = []
    @State private var showingImportPreview = false
    @State private var showingHistory = false
    @State private var currentFileName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !healthKitManager.isAuthorized {
                        HealthKitAuthorizationView(healthKitManager: healthKitManager)
                    } else {
                        importSection
                        
                        if !parsedReadings.isEmpty {
                            recentReadingsSection
                        } else if !historyManager.records.isEmpty {
                            importHistorySection
                        } else {
                            emptyStateSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground).ignoresSafeArea())
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Status", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingImportPreview) {
                ImportPreviewView(
                    readings: parsedReadings,
                    healthKitManager: healthKitManager,
                    onImportComplete: { success, message in
                        showingImportPreview = false
                        alertMessage = message
                        showingAlert = true
                        
                        historyManager.addRecord(
                            fileName: currentFileName,
                            readings: parsedReadings,
                            success: success,
                            error: success ? nil : message
                        )
                        
                        if success {
                            parsedReadings.removeAll()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingHistory) {
                ImportHistoryView(historyManager: historyManager)
            }
        }
        .onAppear {
            checkForIncomingFile()
        }
        .onChange(of: fileHandler.hasIncomingFile) { _ in
            checkForIncomingFile()
        }
    }
    
    private var importSection: some View {
        VStack(spacing: 20) {
            Text("Import Blood Pressure Data")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Import CSV files from your OxiPro BP2 monitor to save readings to Apple Health.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            Button(action: {
                showingImporter = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title3)
                    Text("Import CSV File")
                        .font(.headline)
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
            .disabled(isImporting)
            .cornerRadius(12)
            
            if isImporting {
                VStack(spacing: 8) {
                    ProgressView(value: importProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    Text("Importing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parsed Readings (\(parsedReadings.count))")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(parsedReadings.prefix(5)) { reading in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(reading.dateTimeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(reading.bloodPressureString)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            if let _ = reading.pulse {
                                VStack(alignment: .trailing) {
                                    Text("Pulse")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(reading.pulseString)
                                        .font(.callout)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Button("Import All to Health") {
                showingImportPreview = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 50)
            .cornerRadius(8)
        }
    }
    
    private var importHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Readings")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Import History") {
                    showingHistory = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                // Get all recent readings from successful imports
                let recentReadings = historyManager.records
                    .filter { $0.success }
                    .prefix(5)
                    .flatMap { $0.readings ?? [] }
                    .sorted { $0.date > $1.date }
                    .prefix(5)
                
                if recentReadings.isEmpty {
                    Text("No readings imported yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(Array(recentReadings), id: \.id) { reading in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reading.dateTimeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Text(reading.bloodPressureString)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    if let pulse = reading.pulse {
                                        Text("\(pulse) bpm")
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
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Text("No Import History Yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Import your first CSV file from the OxiPro BP2 monitor to get started. You can either use the import button above or share CSV files directly to this app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            isImporting = true
            importProgress = 0
            
            Task {
                do {
                    // Start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        await MainActor.run {
                            self.isImporting = false
                            self.alertMessage = "Failed to access file: Permission denied"
                            self.showingAlert = true
                        }
                        return
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    let data = try Data(contentsOf: url)
                    let readings = try CSVParser.parse(csvData: data)
                    
                    await MainActor.run {
                        self.parsedReadings = readings
                        self.isImporting = false
                        self.currentFileName = url.lastPathComponent
                        
                        if readings.isEmpty {
                            alertMessage = "No valid readings found in the CSV file"
                            showingAlert = true
                        } else {
                            showingImportPreview = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isImporting = false
                        self.alertMessage = "Failed to parse CSV: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
            
        case .failure(let error):
            alertMessage = "Failed to import file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func checkForIncomingFile() {
        guard fileHandler.hasIncomingFile,
              let url = fileHandler.incomingFileURL else { return }
        
        fileHandler.clearIncomingFile()
        
        Task {
            do {
                // For copied files in documents directory, no security scoping needed
                let data = try Data(contentsOf: url)
                let readings = try CSVParser.parse(csvData: data)
                
                await MainActor.run {
                    self.parsedReadings = readings
                    self.currentFileName = url.lastPathComponent
                    if readings.isEmpty {
                        alertMessage = "No valid readings found in the CSV file"
                        showingAlert = true
                    } else {
                        showingImportPreview = true
                    }
                }
                
                // Clean up the copied file
                try? FileManager.default.removeItem(at: url)
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to parse CSV: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(IncomingFileHandler())
}
