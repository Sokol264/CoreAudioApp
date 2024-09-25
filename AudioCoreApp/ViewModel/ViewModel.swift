//
//  ViewModel.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 14.09.2024.
//

import Combine
import Foundation
import AVFAudio

final class ViewModel {
    enum PitchLevel {
        case high
        case low
    }

    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isHighPitchPlaying: Bool = false
    @Published var isLowPitchPlaying: Bool = false

    private let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer()
    private let pdfManager = PDFManager()
    private let audioSessionManager = AudioManager()

    private var playingSubscription: AnyCancellable?

    init() {
        observeRecording()
    }
}

// MARK: View Actioning
extension ViewModel {
    func recordButtonTapped() {
        if !isRecording {
            audioSessionManager.startRecording()
            audioRecorder.startRecording()
        } else {
            audioSessionManager.stopRecording()
            audioRecorder.stopRecording()
        }
    }

    func playButtonTapped(with pitchLevel: PitchLevel? = nil) {
        audioSessionManager.startPlaying()
        observePlaying(with: pitchLevel)

        if isHighPitchPlaying || isLowPitchPlaying || isPlaying {
            audioPlayer.stopPlaying()
            audioSessionManager.stopPlaying()
        } else {
            switch pitchLevel {
            case .high:
                audioPlayer.startPlaying(pitchValue: 600.0)
            case .low:
                audioPlayer.startPlaying(pitchValue: -600.0)
            case .none:
                audioPlayer.startPlaying()
            }
        }
    }

    func pdfPreviewTapped() -> Data {
        pdfManager.createGraphDocumentData(with: audioRecorder.audioSamples)
    }
}

// MARK: Helper methods
private extension ViewModel {
    func observePlaying(with level: PitchLevel? = nil) {
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
