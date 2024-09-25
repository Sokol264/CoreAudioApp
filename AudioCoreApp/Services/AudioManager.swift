//
//  AudioManager.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 15.09.2024.
//

import AVFoundation

final class AudioManager: NSObject {
    var audioSession = AVAudioSession.sharedInstance()

    func requestAccess(completion: @escaping (Bool) -> ()) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { result in
                completion(result)
            }
        } else {
            audioSession.requestRecordPermission { result in
                completion(result)
            }
        }
    }

    func startRecording() {
        do {
            try audioSession.setCategory(.record, options: [.allowBluetooth])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print(error)
        }
    }

    func stopRecording() {
        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print(error)
        }
    }

    func startPlaying() {
        do {
            try audioSession.setCategory(.playback, options: [.allowBluetooth])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print(error)
        }
    }

    func stopPlaying() {
        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print(error)
        }
    }
}
