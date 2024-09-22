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
    
    private let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer()
    private let audioManager = AudioManager()
    private let pdfManager = PDFManager()
    
    private var subcsriptions = Set<AnyCancellable>()
    
    init() {
        audioPlayer.$isPlaying
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying
            }
            .store(in: &subcsriptions)
    }
    
    func recordButtonTapped() {
        if !isRecording {
            audioRecorder.startRecording()
        } else {
            audioRecorder.stopRecording()
        }
        
        isRecording.toggle()
    }
    
    func playButtonTapped() {
        if isPlaying {
            audioPlayer.stopPlaying()
        } else {
            audioPlayer.startPlaying()
        }
    }
    
    func playWithPitch(level: AudioManager.PitchLevel) {
        try? audioManager.startPlaying(with: level)
    }
    
    func pdfPreviewTapped() -> Data {
        pdfManager.createFlyer()
    }
}
