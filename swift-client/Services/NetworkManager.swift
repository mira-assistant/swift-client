import Foundation
import CoreLocation
import UIKit

class NetworkManager: ObservableObject {
    @Published var isServiceEnabled = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var interactionData: [InteractionData] = []
    @Published var connectedClients: [String] = []
    @Published var clientRSSI: [String: Double] = [:]
    @Published var isBackendAvailable = true
    
    private let baseURL = "https://api.mira-assistant.com" // Replace with actual backend URL
    private let session = URLSession.shared
    private let clientId: String
    
    init() {
        // Load client ID from UserDefaults, generate default if not exists
        if let savedClientId = UserDefaults.standard.string(forKey: "ClientID"), !savedClientId.isEmpty {
            self.clientId = savedClientId
        } else {
            // Generate client ID from device name in format like "ankurs-iphone"
            let deviceName = UIDevice.current.name
            let generatedId = deviceName
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "'", with: "")
            self.clientId = generatedId
            // Save the generated ID
            UserDefaults.standard.set(generatedId, forKey: "ClientID")
        }
    }
    
    // MARK: - Service Toggle
    
    func enableService() async {
        await toggleService(enable: true)
    }
    
    func disableService() async {
        await toggleService(enable: false)
    }
    
    private func toggleService(enable: Bool) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let endpoint = enable ? "/api/enable" : "/api/disable"
        guard let url = URL(string: baseURL + endpoint) else {
            await setError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                await MainActor.run {
                    self.isServiceEnabled = enable
                    self.isBackendAvailable = true
                }
            } else {
                await setError("Failed to \(enable ? "enable" : "disable") service")
                await MainActor.run {
                    self.isBackendAvailable = false
                }
            }
        } catch {
            await setError(error.localizedDescription)
            await MainActor.run {
                self.isBackendAvailable = false
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Client Discovery and RSSI
    
    func fetchConnectedClients() async {
        guard let url = URL(string: baseURL + "/") else {
            await setError("Invalid URL")
            return
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                // Parse the root endpoint response to extract client IDs
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clients = json["connected_clients"] as? [String: Any] {
                    
                    let clientIds = Array(clients.keys)
                    await MainActor.run {
                        self.connectedClients = clientIds
                    }
                    
                    // Calculate RSSI for each client
                    await calculateAndReportRSSI(for: clientIds)
                }
            } else {
                await setError("Failed to fetch connected clients")
            }
        } catch {
            await setError("Failed to fetch clients: \(error.localizedDescription)")
        }
    }
    
    private func calculateAndReportRSSI(for clientIds: [String]) async {
        for clientId in clientIds {
            // Simulate RSSI calculation (in real implementation, this would use actual signal strength measurement)
            let simulatedRSSI = Double.random(in: -80...(-30)) // Typical RSSI range
            
            await MainActor.run {
                self.clientRSSI[clientId] = simulatedRSSI
            }
            
            await reportRSSI(simulatedRSSI, for: clientId)
        }
    }
    
    private func reportRSSI(_ rssi: Double, for clientId: String) async {
        guard let url = URL(string: baseURL + "/streams/phone/rssi") else {
            await setError("Invalid RSSI URL")
            return
        }
        
        let rssiData = RSSIReport(
            client_id: self.clientId,
            rssi: rssi
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(rssiData)
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                await setError("Failed to report RSSI")
            }
        } catch {
            await setError("Failed to report RSSI: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Location Reporting
    
    func reportLocation(_ location: CLLocation) async {
        guard let url = URL(string: baseURL + "/streams/phone/location") else {
            await setError("Invalid URL")
            return
        }
        
        let locationData = LocationReport(
            client_id: clientId,
            location: LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(locationData)
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                await setError("Failed to report location")
            }
        } catch {
            await setError("Failed to report location: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Interaction Data
    
    func fetchInteractionData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: baseURL + "/api/interactions") else {
            await setError("Invalid URL")
            return
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let interactions = try decoder.decode([InteractionData].self, from: data)
                
                await MainActor.run {
                    self.interactionData = interactions
                }
            } else {
                await setError("Failed to fetch interaction data")
            }
        } catch {
            await setError("Failed to fetch data: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Audio Embedding
    
    func trainAudioEmbedding(personIndex: Int = 1) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: baseURL + "/api/audio/train") else {
            await setError("Invalid URL")
            return
        }
        
        let trainingRequest = AudioTrainingRequest(personIndex: personIndex)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(trainingRequest)
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                await setError("Failed to start audio training")
            }
        } catch {
            await setError("Failed to start training: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Search Functions
    
    func searchPersons(query: String) async -> [PersonSearchResult] {
        guard let url = URL(string: baseURL + "/search") else {
            await setError("Invalid search URL")
            return []
        }
        
        let searchRequest = PersonSearchRequest(query: query)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(searchRequest)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let results = try decoder.decode([PersonSearchResult].self, from: data)
                return results
            } else {
                await setError("Failed to search persons")
                return []
            }
        } catch {
            await setError("Failed to search: \(error.localizedDescription)")
            return []
        }
    }
    
    func searchInteractions(query: String) async -> [InteractionSearchResult] {
        guard let url = URL(string: baseURL + "/interactions/search") else {
            await setError("Invalid interaction search URL")
            return []
        }
        
        let searchRequest = InteractionSearchRequest(query: query)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(searchRequest)
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let results = try decoder.decode([InteractionSearchResult].self, from: data)
                return results
            } else {
                await setError("Failed to search interactions")
                return []
            }
        } catch {
            await setError("Failed to search interactions: \(error.localizedDescription)")
            return []
        }
    }
    
    private func setError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
        }
    }
}

// MARK: - Data Models

struct LocationReport: Codable {
    let client_id: String
    let location: LocationData
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
}

struct RSSIReport: Codable {
    let client_id: String
    let rssi: Double
}

struct InteractionData: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: String
    let duration: Double?
    let distance: Double?
    let personIndex: Int?
    
    init(id: UUID = UUID(), timestamp: Date, type: String, duration: Double? = nil, distance: Double? = nil, personIndex: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.duration = duration
        self.distance = distance
        self.personIndex = personIndex
    }
}

struct AudioTrainingRequest: Codable {
    let personIndex: Int
}

struct PersonSearchRequest: Codable {
    let query: String
}

struct InteractionSearchRequest: Codable {
    let query: String
}

struct PersonSearchResult: Identifiable, Codable {
    let id: UUID
    let index: Int
    let name: String
    let confidence: Double
}

struct InteractionSearchResult: Identifiable, Codable {
    let id: UUID
    let type: String
    let timestamp: Date
    let content: String
    let relevance: Double
}
