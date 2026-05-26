//
//  ExportReportView.swift
//  oxiproimport
//

import SwiftUI

struct ExportReportView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss

    enum RangePreset: String, CaseIterable, Identifiable {
        case week, month, threeMonths, year, all
        var id: String { rawValue }

        var label: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .threeMonths: return "3 Months"
            case .year: return "Year"
            case .all: return "All"
            }
        }

        func startDate(relativeTo end: Date) -> Date {
            let calendar = Calendar.current
            switch self {
            case .week:
                return calendar.date(byAdding: .weekOfYear, value: -1, to: end) ?? end
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: end) ?? end
            case .threeMonths:
                return calendar.date(byAdding: .month, value: -3, to: end) ?? end
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: end) ?? end
            case .all:
                return Date.distantPast
            }
        }
    }

    @State private var selectedRange: RangePreset = .month
    @State private var readings: [BloodPressureReading] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var patientName = ""
    @State private var includePatientName = false
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(RangePreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Summary") {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading from Health\u{2026}")
                                .foregroundColor(.secondary)
                        }
                    } else if let loadError {
                        Text(loadError)
                            .foregroundColor(.red)
                            .font(.callout)
                    } else {
                        HStack {
                            Text("Readings")
                            Spacer()
                            Text("\(readings.count)")
                                .foregroundColor(.secondary)
                        }
                        if let range = formattedRange {
                            HStack {
                                Text("Period")
                                Spacer()
                                Text(range)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Report Options") {
                    Toggle("Include Patient Name", isOn: $includePatientName)
                    if includePatientName {
                        TextField("Patient Name", text: $patientName)
                    }
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(isLoading || readings.isEmpty)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: generateShareItems())
            }
        }
        .task(id: selectedRange) {
            await loadReadings()
        }
    }

    private var formattedRange: String? {
        guard let first = readings.last?.date, let last = readings.first?.date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }

    private func loadReadings() async {
        isLoading = true
        loadError = nil
        let end = Date()
        let start = selectedRange.startDate(relativeTo: end)
        do {
            let fetched = try await healthKitManager.fetchAllReadings(from: start, to: end)
            await MainActor.run {
                self.readings = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.loadError = "Failed to load: \(error.localizedDescription)"
                self.readings = []
                self.isLoading = false
            }
        }
    }

    private func generateShareItems() -> [Any] {
        let content = ReportGenerator.generateReport(
            from: readings,
            patientName: includePatientName && !patientName.isEmpty ? patientName : nil
        )
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Blood_Pressure_Report_\(selectedRange.label.replacingOccurrences(of: " ", with: "_"))_\(formatter.string(from: Date())).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return [tempURL]
        } catch {
            return [content]
        }
    }
}
