//
//  HealthKitManager.swift
//  oxiproimport
//
//  Created on 28/07/2025.
//

import Foundation
import HealthKit
import Combine

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
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
        
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
    
    func saveMultipleReadings(_ readings: [BloodPressureReading], progress: @escaping (Double) -> Void) async throws {
        let total = Double(readings.count)
        var completed = 0.0
        
        for reading in readings {
            try await saveBloodPressureReading(reading)
            completed += 1
            await MainActor.run {
                progress(completed / total)
            }
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