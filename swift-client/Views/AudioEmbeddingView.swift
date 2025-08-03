import SwiftUI
import AVFoundation

struct AudioTrainingView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @State private var searchText = ""
    @State private var searchResults: [PersonSearchResult] = []
    @State private var isSearching = false
    @State private var showingTraining = false
    @State private var personIndex = 1
    @State private var isRecording = false
    @State private var recordingLevel: Float = 0.0
    @State private var currentPhrase = 0
    
    private let trainingPhrases = [
        "Hey Mira, how are you?",
        "Hey Mira, what's the weather like?",
        "Hey Mira, play some music",
        "Hey Mira, set a reminder",
        "Hey Mira, what time is it?"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            if showingTraining {
                trainingView
            } else {
                searchView
            }
        }
        .onAppear {
            requestMicrophonePermission()
        }
    }
    
    private var searchView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Audio Training")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Search for existing persons or train a new voice")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Search Bar
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name, index, or upload audio...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                
                // Search Results
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Results")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(searchResults) { result in
                            PersonResultRow(result: result) {
                                // Select this person for training
                                personIndex = result.index
                                showingTraining = true
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Quick Actions
            VStack(spacing: 12) {
                Button("Train New Person") {
                    personIndex = getNextAvailableIndex()
                    showingTraining = true
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Browse All Persons") {
                    searchText = ""
                    performSearch()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
    }
    
    private var trainingView: some View {
        VStack(spacing: 32) {
            // Back Button
            HStack {
                Button("← Back to Search") {
                    showingTraining = false
                    currentPhrase = 0
                }
                .foregroundColor(.green)
                
                Spacer()
            }
            
            // Progress Indicator
            HStack(spacing: 8) {
                ForEach(0..<trainingPhrases.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPhrase ? .green : .gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            VStack(spacing: 16) {
                Text("Training Person \(personIndex)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\"\(trainingPhrases[currentPhrase])\"")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // Microphone Visualization
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(.green.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(.green.opacity(isRecording ? 0.2 : 0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }
                
                if isRecording {
                    VStack(spacing: 8) {
                        // Simple audio level bars
                        HStack(spacing: 4) {
                            ForEach(0..<5) { bar in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.green)
                                    .frame(width: 4, height: CGFloat.random(in: 8...24))
                                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: recordingLevel)
                            }
                        }
                        
                        Text("Listening...")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Control Buttons
            VStack(spacing: 16) {
                if !isRecording {
                    Button("Start Recording") {
                        startRecording()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Stop & Continue") {
                        stopRecording()
                    }
                    .buttonStyle(DangerButtonStyle())
                }
                
                if currentPhrase > 0 {
                    Button("Previous Phrase") {
                        currentPhrase = max(0, currentPhrase - 1)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            
            // Error Message
            if let error = networkManager.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            Task {
                await loadAllPersons()
            }
            return
        }
        
        isSearching = true
        
        Task {
            await searchPersons(query: searchText)
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func searchPersons(query: String) async {
        let results = await networkManager.searchPersons(query: query)
        await MainActor.run {
            searchResults = results
        }
    }
    
    private func loadAllPersons() async {
        // Load all persons from backend by searching with empty query or special endpoint
        let results = await networkManager.searchPersons(query: "")
        await MainActor.run {
            searchResults = results
        }
    }
    
    private func getNextAvailableIndex() -> Int {
        let usedIndices = Set(searchResults.map { $0.index })
        for i in 1...100 {
            if !usedIndices.contains(i) {
                return i
            }
        }
        return 1
    }
    
    private func startRecording() {
        isRecording = true
        
        // Simulate audio level changes for demo
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isRecording {
                timer.invalidate()
                recordingLevel = 0.0
                return
            }
            recordingLevel = Float.random(in: 0.1...1.0)
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recordingLevel = 0.0
        
        // Submit the recording to backend
        Task {
            await networkManager.trainAudioEmbedding(personIndex: personIndex)
            
            // Move to next phrase or complete training
            await MainActor.run {
                if currentPhrase < trainingPhrases.count - 1 {
                    currentPhrase += 1
                } else {
                    // Training complete
                    showingTraining = false
                    currentPhrase = 0
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    // Handle permission denied
                }
            }
        }
    }
}

struct PersonResultRow: View {
    let result: PersonSearchResult
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Person \(result.index) • \(Int(result.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.red, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    AudioTrainingView()
        .environmentObject(NetworkManager())
}