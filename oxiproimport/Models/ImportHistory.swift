//
//  ImportHistory.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import Foundation
import Combine

struct ImportRecord: Identifiable, Codable {
    let id = UUID()
    let fileName: String
    let importDate: Date
    let readingsCount: Int
    let dateRange: String
    let success: Bool
    let errorMessage: String?
    let readings: [BloodPressureReading]?
    
    var importDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: importDate)
    }
}

class ImportHistoryManager: ObservableObject {
    @Published var records: [ImportRecord] = []
    
    private let userDefaults = UserDefaults.standard
    private let recordsKey = "ImportHistory"
    private let maxRecords = 50
    
    init() {
        loadRecords()
    }
    
    func addRecord(fileName: String, readings: [BloodPressureReading], success: Bool, error: String? = nil) {
        let dateRange: String
        if let firstDate = readings.last?.date,
           let lastDate = readings.first?.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateRange = "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        } else {
            dateRange = "N/A"
        }
        
        let record = ImportRecord(
            fileName: fileName,
            importDate: Date(),
            readingsCount: readings.count,
            dateRange: dateRange,
            success: success,
            errorMessage: error,
            readings: success ? readings : nil
        )
        
        records.insert(record, at: 0)
        
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        
        saveRecords()
    }
    
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: recordsKey),
              let decoded = try? JSONDecoder().decode([ImportRecord].self, from: data) else {
            return
        }
        records = decoded
    }
    
    private func saveRecords() {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        userDefaults.set(encoded, forKey: recordsKey)
    }
    
    func clearHistory() {
        records.removeAll()
        userDefaults.removeObject(forKey: recordsKey)
    }
}