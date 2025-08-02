import SwiftUI
import AVFoundation

struct AudioEmbeddingView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var personIndex = 1
    @State private var isRecording = false
    @State private var recordingLevel: Float = 0.0
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Audio Training")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Train personal audio embedding")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Person Index Selection
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                        Text("Person Configuration")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Person Index:")
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            Picker("Person Index", selection: $personIndex) {
                                ForEach(1...10, id: \.self) { index in
                                    Text("Person \(index)")
                                        .tag(index)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        Text("Default: Person 1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Recording Visualization
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(isRecording ? .red : .gray)
                        Text("Audio Level")
                            .font(.headline)
                    }
                    
                    // Audio level visualization
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 20)
                        
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.green.gradient)
                                .frame(width: CGFloat(recordingLevel) * 250, height: 20)
                            Spacer()
                        }
                    }
                    .frame(width: 250)
                    
                    if isRecording {
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .opacity(0.8)
                            Text("Recording...")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Training Controls
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await networkManager.trainAudioEmbedding(personIndex: personIndex)
                        }
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Start Training")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                    }
                    .disabled(networkManager.isLoading)
                    
                    Button(action: {
                        toggleRecording()
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRecording ? .red.gradient : .blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                    }
                    
                    if networkManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Training in progress...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = networkManager.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Training Information
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Training Tips")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(text: "Speak clearly and naturally")
                        TipRow(text: "Record in a quiet environment")
                        TipRow(text: "Provide 10-15 seconds of audio")
                        TipRow(text: "Use consistent speaking volume")
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            requestMicrophonePermission()
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
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
        recordingLevel = 0.0
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

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    AudioEmbeddingView()
}