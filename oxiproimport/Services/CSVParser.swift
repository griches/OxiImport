//
//  CSVParser.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import Foundation

class CSVParser {
    static func parse(csvData: Data) throws -> [BloodPressureReading] {
        guard let csvString = String(data: csvData, encoding: .utf8) else {
            throw CSVParsingError.emptyFile
        }
        
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw CSVParsingError.emptyFile
        }
        
        let headers = parseCSVLine(lines[0])
        let requiredHeaders = ["Date", "Time", "Sys", "Dia"]
        
        for required in requiredHeaders {
            if !headers.contains(required) {
                throw CSVParsingError.missingRequiredColumns
            }
        }
        
        var readings: [BloodPressureReading] = []
        
        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])
            
            if values.count >= headers.count {
                var row: [String: String] = [:]
                for (index, header) in headers.enumerated() {
                    row[header] = values[index]
                }
                
                if let dateString = row["Date"],
                   let timeString = row["Time"],
                   !dateString.isEmpty && !timeString.isEmpty {
                    do {
                        let reading = try BloodPressureReading.from(
                            csvRow: row,
                            dateString: dateString,
                            timeString: timeString
                        )
                        readings.append(reading)
                    } catch {
                        print("Failed to parse row \(i): \(error)")
                    }
                }
            }
        }
        
        return readings.sorted { $0.date > $1.date }
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return result
    }
}