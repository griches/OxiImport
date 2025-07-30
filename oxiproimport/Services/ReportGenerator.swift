//
//  ReportGenerator.swift
//  oxiproimport
//
//  Created on 30/07/2025.
//

import Foundation

class ReportGenerator {
    
    static func generateReport(from readings: [BloodPressureReading], patientName: String? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        var report = "BLOOD PRESSURE REPORT\n"
        report += "====================\n\n"
        
        if let name = patientName {
            report += "Patient: \(name)\n"
        }
        
        report += "Generated: \(dateFormatter.string(from: Date()))\n"
        report += "Total Readings: \(readings.count)\n\n"
        
        if let firstDate = readings.last?.date,
           let lastDate = readings.first?.date {
            report += "Period: \(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))\n\n"
        }
        
        let stats = calculateStatistics(from: readings)
        report += "SUMMARY STATISTICS\n"
        report += "-----------------\n"
        report += "Systolic: Avg \(stats.avgSystolic) (Range: \(stats.minSystolic)-\(stats.maxSystolic))\n"
        report += "Diastolic: Avg \(stats.avgDiastolic) (Range: \(stats.minDiastolic)-\(stats.maxDiastolic))\n"
        if stats.avgPulse > 0 {
            report += "Heart Rate: Avg \(stats.avgPulse) bpm (Range: \(stats.minPulse)-\(stats.maxPulse))\n"
        }
        report += "\n"
        
        report += "DETAILED READINGS\n"
        report += "-----------------\n"
        
        for reading in readings {
            report += "\(dateFormatter.string(from: reading.date)) at \(timeFormatter.string(from: reading.date))\n"
            report += "  Blood Pressure: \(reading.bloodPressureString) mmHg\n"
            if let pulse = reading.pulse {
                report += "  Heart Rate: \(pulse) bpm\n"
            }
            if reading.irregularPulseDetected {
                report += "  ⚠️ Irregular pulse detected\n"
            }
            report += "  Device: \(reading.source)\n\n"
        }
        
        report += "\nNote: This report is generated from imported OxiPro BP2 data.\n"
        report += "Please consult with your healthcare provider for medical advice.\n"
        
        return report
    }
    
    static func generateCSV(from readings: [BloodPressureReading]) -> String {
        var csv = "Date,Time,Systolic,Diastolic,Heart Rate,Irregular Pulse,Device\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for reading in readings {
            let date = dateFormatter.string(from: reading.date)
            let time = timeFormatter.string(from: reading.date)
            let pulse = reading.pulse.map { String($0) } ?? "N/A"
            let irregular = reading.irregularPulseDetected ? "Yes" : "No"
            
            csv += "\(date),\(time),\(reading.systolic),\(reading.diastolic),\(pulse),\(irregular),\(reading.source)\n"
        }
        
        return csv
    }
    
    private static func calculateStatistics(from readings: [BloodPressureReading]) -> Statistics {
        guard !readings.isEmpty else {
            return Statistics(
                avgSystolic: 0, minSystolic: 0, maxSystolic: 0,
                avgDiastolic: 0, minDiastolic: 0, maxDiastolic: 0,
                avgPulse: 0, minPulse: 0, maxPulse: 0
            )
        }
        
        let systolicValues = readings.map { $0.systolic }
        let diastolicValues = readings.map { $0.diastolic }
        let pulseValues = readings.compactMap { $0.pulse }
        
        return Statistics(
            avgSystolic: systolicValues.reduce(0, +) / systolicValues.count,
            minSystolic: systolicValues.min() ?? 0,
            maxSystolic: systolicValues.max() ?? 0,
            avgDiastolic: diastolicValues.reduce(0, +) / diastolicValues.count,
            minDiastolic: diastolicValues.min() ?? 0,
            maxDiastolic: diastolicValues.max() ?? 0,
            avgPulse: pulseValues.isEmpty ? 0 : pulseValues.reduce(0, +) / pulseValues.count,
            minPulse: pulseValues.min() ?? 0,
            maxPulse: pulseValues.max() ?? 0
        )
    }
    
    private struct Statistics {
        let avgSystolic: Int
        let minSystolic: Int
        let maxSystolic: Int
        let avgDiastolic: Int
        let minDiastolic: Int
        let maxDiastolic: Int
        let avgPulse: Int
        let minPulse: Int
        let maxPulse: Int
    }
}