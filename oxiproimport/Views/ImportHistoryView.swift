//
//  ImportHistoryView.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import SwiftUI
import Combine

struct ImportHistoryView: View {
    @ObservedObject var historyManager: ImportHistoryManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationView {
            Group {
                if historyManager.records.isEmpty {
                    emptyHistoryView
                } else {
                    historyList
                }
            }
            .navigationTitle("Import History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !historyManager.records.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: $showingClearConfirmation) {
                Button("Clear All History", role: .destructive) {
                    historyManager.clearHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all import history. This action cannot be undone.")
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Import History")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Your import history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var historyList: some View {
        List(historyManager.records) { record in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.fileName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(record.importDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.success ? .green : .red)
                        .imageScale(.large)
                }
                
                HStack(spacing: 16) {
                    Label("\(record.readingsCount) readings", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if record.dateRange != "N/A" {
                        Label(record.dateRange, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = record.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(PlainListStyle())
    }
}

#Preview {
    ImportHistoryView(historyManager: ImportHistoryManager())
}