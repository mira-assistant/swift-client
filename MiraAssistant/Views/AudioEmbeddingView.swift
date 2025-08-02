import SwiftUI
import AVFoundation

struct AudioEmbeddingView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var personIndex = 1
    @State private var isRecording = false
    @State private var recordingLevel: Float = 0.0
    @State private var currentPhrase = 0
    @State private var hasStartedTraining = false
    
    private let trainingPhrases = [
        "Hey Mira, how are you?",
        "Hey Mira, what's the weather like?",
        "Hey Mira, play some music",
        "Hey Mira, set a reminder",
        "Hey Mira, what time is it?"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 40) {
                Spacer()
                
                if !hasStartedTraining {
                    // Initial Setup Screen
                    VStack(spacing: 24) {
                        Image(systemName: "mic.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 16) {
                            Text("Set Up Audio Training")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Train Mira to recognize your voice by reading a few short phrases.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Person:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                Picker("Person", selection: $personIndex) {
                                    ForEach(1...10, id: \.self) { index in
                                        Text("Person \(index)")
                                            .tag(index)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            hasStartedTraining = true
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    // Training Screen
                    VStack(spacing: 32) {
                        // Progress Indicator
                        HStack(spacing: 8) {
                            ForEach(0..<trainingPhrases.count, id: \.self) { index in
                                Circle()
                                    .fill(index <= currentPhrase ? .green : .gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            Text("Say the phrase")
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
                                Button(action: {
                                    startRecording()
                                }) {
                                    HStack {
                                        Image(systemName: "mic.circle.fill")
                                        Text("Start Recording")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal, 40)
                            } else {
                                Button(action: {
                                    stopRecording()
                                }) {
                                    HStack {
                                        Image(systemName: "stop.circle.fill")
                                        Text("Stop & Continue")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.red, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal, 40)
                            }
                            
                            if currentPhrase > 0 {
                                Button(action: {
                                    currentPhrase = max(0, currentPhrase - 1)
                                }) {
                                    Text("Previous Phrase")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Error Message
                if let error = networkManager.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .onAppear {
            requestMicrophonePermission()
        }
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
                    hasStartedTraining = false
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

#Preview {
    AudioEmbeddingView()
}