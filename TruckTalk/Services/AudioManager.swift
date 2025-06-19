import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentAudioId: String?
    @Published var playbackProgress: Double = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playAudio(fileName: String, audioId: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file not found: \(fileName)")
            return
        }
        
        do {
            // Stop current audio if playing
            stopAudio()
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            currentAudioId = audioId
            isPlaying = true
            playbackProgress = 0.0
            
            audioPlayer?.play()
            startProgressTimer()
            
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentAudioId = nil
        playbackProgress = 0.0
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
            self?.stopProgressTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.stopAudio()
        }
        if let error = error {
            print("Audio decode error: \(error)")
        }
    }
} 