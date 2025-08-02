import Foundation
import CoreLocation

class NetworkManager: ObservableObject {
    @Published var isServiceEnabled = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var interactionData: [InteractionData] = []
    
    private let baseURL = "https://api.mira-assistant.com" // Replace with actual backend URL
    private let session = URLSession.shared
    
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
                }
            } else {
                await setError("Failed to \(enable ? "enable" : "disable") service")
            }
        } catch {
            await setError(error.localizedDescription)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Distance Reporting
    
    func reportDistance(_ distance: Double, from location: CLLocation) async {
        guard let url = URL(string: baseURL + "/api/distance") else {
            await setError("Invalid URL")
            return
        }
        
        let distanceData = DistanceReport(
            distance: distance,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date()
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(distanceData)
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                await setError("Failed to report distance")
            }
        } catch {
            await setError("Failed to report distance: \(error.localizedDescription)")
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
    
    // MARK: - Helper Methods
    
    private func setError(_ message: String) async {
        await MainActor.run {
            self.errorMessage = message
            self.isLoading = false
        }
    }
}

// MARK: - Data Models

struct DistanceReport: Codable {
    let distance: Double
    let latitude: Double
    let longitude: Double
    let timestamp: Date
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