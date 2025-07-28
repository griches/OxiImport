//
//  oxiproimportApp.swift
//  oxiproimport
//
//  Created by Gary Riches on 28/07/2025.
//

import SwiftUI
import Combine

@main
struct oxiproimportApp: App {
    @StateObject private var fileHandler = IncomingFileHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileHandler)
                .onOpenURL { url in
                    fileHandler.handleIncomingFile(url)
                }
        }
    }
}

class IncomingFileHandler: ObservableObject {
    @Published var incomingFileURL: URL?
    @Published var hasIncomingFile = false
    
    func handleIncomingFile(_ url: URL) {
        guard url.pathExtension.lowercased() == "csv" else { return }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            DispatchQueue.main.async {
                self.incomingFileURL = destinationURL
                self.hasIncomingFile = true
            }
        } catch {
            print("Error handling incoming file: \(error)")
        }
    }
    
    func clearIncomingFile() {
        incomingFileURL = nil
        hasIncomingFile = false
    }
}
