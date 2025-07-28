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
        NavigationView {
            VStack(spacing: 20) {
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
            .padding()
            .navigationTitle("OxiPro Import")
            .toolbar {
                if !historyManager.records.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
            }
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
        VStack(spacing: 16) {
            Text("Import Blood Pressure Data")
                .font(.headline)
            
            Text("Import CSV files from your OxiPro BP2 monitor to save readings to Apple Health")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingImporter = true
            }) {
                Label("Import CSV File", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
            
            if isImporting {
                ProgressView(value: importProgress) {
                    Text("Importing...")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
                        .cornerRadius(8)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Button("Import All to Health") {
                showingImportPreview = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var importHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Imports")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(historyManager.records.prefix(5)) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.fileName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(record.importDateString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Label("\(record.readingsCount) readings", systemImage: "doc.text")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    if record.dateRange != "N/A" {
                                        Label(record.dateRange, systemImage: "calendar")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(record.success ? .green : .red)
                                .imageScale(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        if let error = record.errorMessage {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding()
            
            Text("No Import History Yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Import your first CSV file from the OxiPro BP2 monitor to get started. You can either use the import button above or share CSV files directly to this app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
