import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentAudioId: String?
    @Published var playbackProgress: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var audioCache: [String: Data] = [:]
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
            errorMessage = "Audio session setup failed"
        }
    }
    
    // MARK: - Audio Playback Methods
    
    /// Play audio from bundle resources
    func playAudio(fileName: String, audioId: String) {
        guard !fileName.isEmpty else {
            print("Audio file name is empty")
            errorMessage = "No audio file specified"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Try to find audio file in bundle
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            playAudioFromURL(url, audioId: audioId)
        } else if let url = Bundle.main.url(forResource: fileName, withExtension: "wav") {
            playAudioFromURL(url, audioId: audioId)
        } else if let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") {
            playAudioFromURL(url, audioId: audioId)
        } else {
            // Fallback to mock audio for testing
            playMockAudio(audioId: audioId)
        }
    }
    
    /// Play audio from remote URL
    func playAudioFromURL(_ urlString: String, audioId: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            errorMessage = "Invalid audio URL"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Check cache first
        if let cachedData = audioCache[urlString] {
            playAudioFromData(cachedData, audioId: audioId)
            return
        }
        
        // Download and cache audio
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    print("Failed to download audio: \(error)")
                    self?.errorMessage = "Failed to download audio"
                    return
                }
                
                guard let data = data else {
                    print("No audio data received")
                    self?.errorMessage = "No audio data received"
                    return
                }
                
                // Cache the audio data
                self?.audioCache[urlString] = data
                
                // Play the audio
                self?.playAudioFromData(data, audioId: audioId)
            }
        }.resume()
    }
    
    /// Play audio from local URL
    private func playAudioFromURL(_ url: URL, audioId: String) {
        do {
            // Stop current audio if playing
            stopAudio()
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            currentAudioId = audioId
            isPlaying = true
            playbackProgress = 0.0
            isLoading = false
            
            audioPlayer?.play()
            startProgressTimer()
            
        } catch {
            print("Failed to play audio from URL: \(error)")
            errorMessage = "Failed to play audio"
            isLoading = false
        }
    }
    
    /// Play audio from data
    private func playAudioFromData(_ data: Data, audioId: String) {
        do {
            // Stop current audio if playing
            stopAudio()
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            currentAudioId = audioId
            isPlaying = true
            playbackProgress = 0.0
            isLoading = false
            
            audioPlayer?.play()
            startProgressTimer()
            
        } catch {
            print("Failed to play audio from data: \(error)")
            errorMessage = "Failed to play audio"
            isLoading = false
        }
    }
    
    /// Play mock audio for testing (generates a beep sound)
    private func playMockAudio(audioId: String) {
        print("🎵 Playing mock audio for: \(audioId)")
        
        // Create a simple beep sound
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let frequency: Double = 440.0 // A4 note
        
        let frameCount = Int(sampleRate * duration)
        var audioData = Data()
        
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let amplitude: Float = 0.3
            let sample = sin(2.0 * Double.pi * frequency * time) * Double(amplitude)
            let sampleInt16 = Int16(sample * 32767.0)
            
            withUnsafeBytes(of: sampleInt16.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        // Add WAV header
        let wavHeader = createWAVHeader(dataSize: UInt32(audioData.count), sampleRate: UInt32(sampleRate))
        let fullAudioData = wavHeader + audioData
        
        playAudioFromData(fullAudioData, audioId: audioId)
    }
    
    /// Create WAV header for mock audio
    private func createWAVHeader(dataSize: UInt32, sampleRate: UInt32) -> Data {
        var header = Data()
        
        // RIFF header
        header.append(contentsOf: "RIFF".utf8)
        header.append(withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) })
        header.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
        header.append(contentsOf: "fmt ".utf8)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // fmt chunk size
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        header.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // channels
        header.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // sample rate
        header.append(withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) }) // byte rate
        header.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // block align
        header.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // bits per sample
        
        // data chunk
        header.append(contentsOf: "data".utf8)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        return header
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentAudioId = nil
        playbackProgress = 0.0
        isLoading = false
        stopProgressTimer()
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func togglePlayback(audioId: String) {
        if currentAudioId == audioId && isPlaying {
            pauseAudio()
        } else if currentAudioId == audioId && !isPlaying {
            resumeAudio()
        } else {
            // Play new audio
            if let fileName = getAudioFileName(for: audioId) {
                playAudio(fileName: fileName, audioId: audioId)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get audio file name for a given audio ID
    private func getAudioFileName(for audioId: String) -> String? {
        // This would be implemented based on your data structure
        // For now, return the audioId as the filename
        return audioId
    }
    
    /// Clear audio cache
    func clearCache() {
        audioCache.removeAll()
    }
    
    /// Get current playback time
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Get total duration
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        Task { @MainActor in
            await updateProgress()
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateProgress()
            }
        }
    }
    
    private func stopProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateProgress() async {
        guard let player = audioPlayer else { return }
        if player.duration > 0 {
            playbackProgress = player.currentTime / player.duration
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.isPlaying = false
            self?.currentAudioId = nil
            self?.playbackProgress = 0.0
            self?.isLoading = false
            self?.stopProgressTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.stopAudio()
            if let error = error {
                print("Audio decode error: \(error)")
                self?.errorMessage = "Audio playback error"
            }
        }
    }
} 