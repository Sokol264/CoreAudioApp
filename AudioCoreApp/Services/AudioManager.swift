//
//  AudioManager.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 15.09.2024.
//

import AVFoundation

final class AudioManager: NSObject {
    enum PitchLevel {
        case high
        case low
    }

    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?

    let engine = AVAudioEngine()
    let speedControl = AVAudioUnitVarispeed()
    let pitchControl = AVAudioUnitTimePitch()

    var audioUrl: URL?
    
    func startRecording() {
        audioUrl = getDocumentsDirectory().appendingPathComponent("recordedAudio.caf")
        
        guard let audioUrl else { return }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioUrl, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            finishRecording(success: false)
        }
    }
    
    func startPlaying(with pitchLevel: PitchLevel?) throws {
        switch pitchLevel {
        case .high:
            pitchControl.pitch = 200
        case .low:
            pitchControl.pitch = -200
        default:
            pitchControl.pitch = 0
        }
        audioUrl = getDocumentsDirectory().appendingPathComponent("recordedAudio.caf")
        guard let audioUrl else { return }

        let file = try AVAudioFile(forReading: audioUrl)

        // 2: create the audio player
        let audioPlayer = AVAudioPlayerNode()

        // 3: connect the components to our playback engine
        engine.attach(audioPlayer)
        engine.attach(pitchControl)
        engine.attach(speedControl)

        // 4: arrange the parts so that output from one is input to another
        engine.connect(audioPlayer, to: speedControl, format: nil)
        engine.connect(speedControl, to: pitchControl, format: nil)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)

        // 5: prepare the player to play its file from the beginning
        audioPlayer.scheduleFile(file, at: nil)

        // 6: start the engine and player
        try engine.start()
        audioPlayer.play()
    }
    
    func pausePlaying() {
        audioPlayer?.pause()
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecording(success: false)
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Finished")
    }
}

private extension AudioManager {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
