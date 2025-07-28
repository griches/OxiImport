//
//  BloodPressureReading.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import Foundation

struct BloodPressureReading: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let systolic: Int
    let diastolic: Int
    let pulse: Int?
    let irregularPulseDetected: Bool
    let source: String
    
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var bloodPressureString: String {
        "\(systolic)/\(diastolic)"
    }
    
    var pulseString: String {
        if let pulse = pulse {
            return "\(pulse) bpm"
        }
        return "N/A"
    }
}

extension BloodPressureReading {
    static func from(csvRow: [String: String], dateString: String, timeString: String) throws -> BloodPressureReading {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone.current
        
        let dateTimeString = "\(dateString) \(timeString)"
        
        guard let date = dateFormatter.date(from: dateTimeString) else {
            throw CSVParsingError.invalidDateFormat
        }
        
        guard let sys = csvRow["Sys"],
              let dia = csvRow["Dia"],
              let systolic = Int(sys),
              let diastolic = Int(dia) else {
            throw CSVParsingError.invalidBloodPressureValues
        }
        
        let pulse = csvRow["Pulse"].flatMap { Int($0) }
        let irregularPulse = csvRow["Irregular pulse"] == "detected"
        let source = csvRow["Source"] ?? "Unknown"
        
        return BloodPressureReading(
            date: date,
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            irregularPulseDetected: irregularPulse,
            source: source
        )
    }
}

enum CSVParsingError: LocalizedError {
    case invalidDateFormat
    case invalidBloodPressureValues
    case missingRequiredColumns
    case emptyFile
    
    var errorDescription: String? {
        switch self {
        case .invalidDateFormat:
            return "Invalid date or time format in CSV file"
        case .invalidBloodPressureValues:
            return "Invalid blood pressure values in CSV file"
        case .missingRequiredColumns:
            return "CSV file is missing required columns"
        case .emptyFile:
            return "CSV file is empty"
        }
    }
}