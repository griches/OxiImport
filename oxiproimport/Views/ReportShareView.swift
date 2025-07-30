//
//  ReportShareView.swift
//  oxiproimport
//
//  Created on 30/07/2025.
//

import SwiftUI

struct ReportShareView: View {
    let record: ImportRecord
    @State private var showingShareSheet = false
    @State private var patientName = ""
    @State private var includePatientName = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Report Details") {
                        HStack {
                            Text("Import Date")
                            Spacer()
                            Text(record.importDateString)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Readings")
                            Spacer()
                            Text("\(record.readingsCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Date Range")
                            Spacer()
                            Text(record.dateRange)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("Report Options") {
                        Toggle("Include Patient Name", isOn: $includePatientName)
                        
                        if includePatientName {
                            TextField("Patient Name", text: $patientName)
                        }
                    }
                }
                
                VStack {
                    Button(action: shareReport) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                            Text("Share Report")
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
                    .disabled(record.readings == nil || record.readings!.isEmpty)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Generate Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: generateShareItems())
            }
        }
    }
    
    private func shareReport() {
        showingShareSheet = true
    }
    
    private func generateShareItems() -> [Any] {
        guard let readings = record.readings else { return [] }
        
        let content = ReportGenerator.generateReport(
            from: readings,
            patientName: includePatientName && !patientName.isEmpty ? patientName : nil
        )
        let fileName = "Blood_Pressure_Report_\(formattedDate()).txt"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return [tempURL]
        } catch {
            print("Error creating report file: \(error)")
            return [content]
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif