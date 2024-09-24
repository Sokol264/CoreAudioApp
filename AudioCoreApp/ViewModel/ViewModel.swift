//
//  ViewModel.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 14.09.2024.
//

import Combine
import Foundation

final class ViewModel {
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isHighPitchPlaying: Bool = false
    @Published var isLowPitchPlaying: Bool = false

    private let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer()
    private let pdfManager = PDFManager()

    private var playingSubscription: AnyCancellable?

    init() {
        observeRecording()
    }
}

// MARK: View Actioning
extension ViewModel {
    func recordButtonTapped() {
        if !isRecording {
            audioRecorder.startRecording()
        } else {
            audioRecorder.stopRecording()
        }
    }

    func playButtonTapped(with pitchLevel: AudioManager.PitchLevel? = nil) {
        observePlaying(with: pitchLevel)

        switch pitchLevel {
        case .high:
            if !isHighPitchPlaying {
                audioPlayer.startPlaying(pitchValue: 600.0)
            } else {
                audioPlayer.stopPlaying()
            }
        case .low:
            if !isLowPitchPlaying {
                audioPlayer.startPlaying(pitchValue: -600.0)
            } else {
                audioPlayer.stopPlaying()
            }
        case .none:
            if !isPlaying {
                audioPlayer.startPlaying()
            } else {
                audioPlayer.stopPlaying()
            }
        }
    }

    func pdfPreviewTapped() -> Data {
        pdfManager.createFlyer()
    }
}

// MARK: Helper methods
private extension ViewModel {
    func observePlaying(with level: AudioManager.PitchLevel? = nil) {
        if playingSubscription == nil {
            playingSubscription?.cancel()
            playingSubscription = nil
        }

        playingSubscription = audioPlayer.$isPlaying
            .sink { [weak self] isPlaying in
                switch level {
                case .high:
                    self?.isHighPitchPlaying = isPlaying
                case .low:
                    self?.isLowPitchPlaying = isPlaying
                case .none:
                    self?.isPlaying = isPlaying
                }

                if !isPlaying {
                    self?.playingSubscription?.cancel()
                    self?.playingSubscription = nil
                }
            }
    }

    func observeRecording() {
        audioRecorder.$isRecording
            .assign(to: &$isRecording)
    }
}
