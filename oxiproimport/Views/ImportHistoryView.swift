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
    @State private var showingClearSheet = false
    
    var body: some View {
        NavigationStack {
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
                            showingClearSheet = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingClearSheet) {
                ClearHistorySheet(
                    onClear: {
                        historyManager.clearHistory()
                        showingClearSheet = false
                    },
                    onCancel: {
                        showingClearSheet = false
                    }
                )
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

struct ClearHistorySheet: View {
    let onClear: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Clear All History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("This will remove all import history. This action cannot be undone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: onClear) {
                        Text("Clear All History")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Clear History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ImportHistoryView(historyManager: ImportHistoryManager())
}