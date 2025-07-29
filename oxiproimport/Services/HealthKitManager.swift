//
//  HealthKitManager.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import Foundation
import HealthKit
import Combine

struct ExistingReading: Hashable, Sendable {
    let date: Date
    let systolic: Int
    let diastolic: Int
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    
    private var bloodPressureType: HKCorrelationType {
        HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
    }
    
    private var systolicType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    }
    
    private var diastolicType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    }
    
    private var heartRateType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .heartRate)!
    }
    
    private var irregularRhythmType: HKCategoryType {
        HKCategoryType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!
    }
    
    func checkHealthKitAvailability() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    private func checkAuthorizationStatus() {
        guard checkHealthKitAvailability() else { return }
        
        let systolicStatus = healthStore.authorizationStatus(for: systolicType)
        let diastolicStatus = healthStore.authorizationStatus(for: diastolicType)
        let heartRateStatus = healthStore.authorizationStatus(for: heartRateType)
        
        // Check if all required types are authorized
        let allAuthorized = systolicStatus == .sharingAuthorized &&
                           diastolicStatus == .sharingAuthorized &&
                           heartRateStatus == .sharingAuthorized
        
        DispatchQueue.main.async {
            self.isAuthorized = allAuthorized
            self.authorizationStatus = systolicStatus // Use systolic as representative status
        }
    }
    
    func requestAuthorization() async throws {
        guard checkHealthKitAvailability() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToWrite: Set<HKSampleType> = [
            systolicType,
            diastolicType,
            heartRateType
        ]
        
        // Also request read permissions for duplicate detection
        let typesToRead: Set<HKObjectType> = [
            bloodPressureType,
            heartRateType
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        
        // Check the actual authorization status after request
        checkAuthorizationStatus()
    }
    
    func saveBloodPressureReading(_ reading: BloodPressureReading) async throws {
        let systolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.systolic))
        let diastolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(reading.diastolic))
        
        let systolicSample = HKQuantitySample(
            type: systolicType,
            quantity: systolicQuantity,
            start: reading.date,
            end: reading.date,
            metadata: ["HKWasUserEntered": true, "Source": reading.source]
        )
        
        let diastolicSample = HKQuantitySample(
            type: diastolicType,
            quantity: diastolicQuantity,
            start: reading.date,
            end: reading.date,
            metadata: ["HKWasUserEntered": true, "Source": reading.source]
        )
        
        let bloodPressureCorrelation = HKCorrelation(
            type: bloodPressureType,
            start: reading.date,
            end: reading.date,
            objects: [systolicSample, diastolicSample],
            metadata: ["HKWasUserEntered": true, "Source": reading.source]
        )
        
        try await healthStore.save(bloodPressureCorrelation)
        
        if let pulse = reading.pulse {
            let heartRateQuantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: Double(pulse))
            let heartRateSample = HKQuantitySample(
                type: heartRateType,
                quantity: heartRateQuantity,
                start: reading.date,
                end: reading.date,
                metadata: ["HKWasUserEntered": true, "Source": reading.source]
            )
            
            try await healthStore.save(heartRateSample)
        }
    }
    
    func saveMultipleReadings(_ readings: [BloodPressureReading], progress: @escaping (Double) -> Void) async throws -> (imported: Int, skipped: Int) {
        guard !readings.isEmpty else {
            return (imported: 0, skipped: 0)
        }
        
        // Find date range for query
        let dates = readings.map { $0.date }
        guard let startDate = dates.min(),
              let endDate = dates.max() else {
            return (imported: 0, skipped: 0)
        }
        
        // Add buffer to date range to ensure we catch all potential duplicates
        let queryStartDate = startDate.addingTimeInterval(-60) // 1 minute before
        let queryEndDate = endDate.addingTimeInterval(60) // 1 minute after
        
        // Query existing readings
        let existingReadings = try await queryBloodPressureReadings(from: queryStartDate, to: queryEndDate)
        
        let total = Double(readings.count)
        var completed = 0.0
        var imported = 0
        var skipped = 0
        
        for reading in readings {
            let existingReading = ExistingReading(
                date: reading.date,
                systolic: reading.systolic,
                diastolic: reading.diastolic
            )
            
            if existingReadings.contains(existingReading) {
                // Skip duplicate
                skipped += 1
            } else {
                // Import new reading
                try await saveBloodPressureReading(reading)
                imported += 1
            }
            
            completed += 1
            await MainActor.run {
                progress(completed / total)
            }
        }
        
        return (imported: imported, skipped: skipped)
    }
    
    func queryBloodPressureReadings(from startDate: Date, to endDate: Date) async throws -> Set<ExistingReading> {
        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: bloodPressureType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var existingReadings = Set<ExistingReading>()
                
                if let correlations = samples as? [HKCorrelation] {
                    for correlation in correlations {
                        if let systolicSample = correlation.objects(for: self.systolicType).first as? HKQuantitySample,
                           let diastolicSample = correlation.objects(for: self.diastolicType).first as? HKQuantitySample {
                            
                            let systolic = Int(systolicSample.quantity.doubleValue(for: .millimeterOfMercury()))
                            let diastolic = Int(diastolicSample.quantity.doubleValue(for: .millimeterOfMercury()))
                            
                            let reading = ExistingReading(
                                date: correlation.startDate,
                                systolic: systolic,
                                diastolic: diastolic
                            )
                            existingReadings.insert(reading)
                        }
                    }
                }
                
                continuation.resume(returning: existingReadings)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .saveFailed:
            return "Failed to save data to HealthKit"
        }
    }
}