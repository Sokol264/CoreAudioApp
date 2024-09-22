//
//  AudioPlayer.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 15.09.2024.
//

import CoreAudioKit

class AudioPlayer {
    @Published var isPlaying = false

    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = [nil, nil, nil, nil]
    private var audioFile: AudioFileID?
    private let fileURL: URL = {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("recordedAudio.caf")
    }()

    private var bufferSize: UInt32 = 1024
    private var packetToRead: UInt32 = 0
    private var currentPacket: Int64 = 0

    private var audioFormat: AudioStreamBasicDescription?
    private var packetFormat = AudioStreamPacketDescription()

    var handleAudioQueueOutput: AudioQueueOutputCallback = { (inUserData, inAQ, inBuffer) in
        let audioPlayer = Unmanaged<AudioPlayer>.fromOpaque(inUserData!).takeUnretainedValue()
        guard let audioFile = audioPlayer.audioFile else { return }

        guard audioPlayer.isPlaying else { return }
        // Обработка входных данных
        var ioNumBytes: UInt32 = inBuffer.pointee.mAudioDataBytesCapacity
        var ioNumPacket: UInt32 = ioNumBytes / 2

        var status = AudioFileReadPacketData(
            audioPlayer.audioFile!,
            false,
            &ioNumBytes,
            nil,
            audioPlayer.currentPacket,
            &ioNumPacket,
            inBuffer.pointee.mAudioData
        )

        if ioNumPacket == 0 || status != noErr {
            audioPlayer.stopPlaying()
            return
        }

        inBuffer.pointee.mAudioDataByteSize = ioNumBytes

        status = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
        guard status == noErr else {
            print("Failed to enqueue buffer: \(status)")
            return
        }

        audioPlayer.currentPacket += Int64(ioNumPacket)
    }

    private func setupAudioQueue() {
        let fileURL = self.fileURL as CFURL
        guard AudioFileOpenURL(fileURL, .readPermission, 0, &audioFile) == noErr else {
            print("Can't open file while output")
            return
        }

        var descSize: UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        var dataFormat = AudioStreamBasicDescription()
        if AudioFileGetProperty(
            audioFile!,
            kAudioFilePropertyDataFormat,
            &descSize,
            &dataFormat
        ) == noErr {
            audioFormat = dataFormat
        } else {
            print("Can't AudioFileGetProperty while output")
            return
        }

        guard var audioFormat = audioFormat else {
            print("No audio formatt while output")
            return
        }

        let userData = Unmanaged.passUnretained(self).toOpaque()

        guard AudioQueueNewOutput(
            &audioFormat,
            handleAudioQueueOutput,
            userData,
            nil,
            nil,
            0,
            &audioQueue
        ) == noErr else {
            print("Can't create audio queue output")
            return
        }

        for i in 0..<audioQueueBuffers.count {
            guard AudioQueueAllocateBuffer(
                audioQueue!,
                bufferSize,
                &audioQueueBuffers[i]
            ) == noErr else {
                print("Failed allocate buffer")
                return
            }

            if let buffer = audioQueueBuffers[i] {
                handleAudioQueueOutput(userData, audioQueue!, buffer)
            }
        }

        AudioQueueSetParameter(audioQueue!, kAudioQueueParam_Volume, 1.0)
    }

    func startPlaying() {
        if isPlaying { return }
        isPlaying = true
        setupAudioQueue()
        currentPacket = 0 // Reset offset
        audioQueueBuffers = [nil, nil, nil, nil]

        guard AudioQueueStart(audioQueue!, nil) == noErr else {
            print("Cant start output")
            return
        }
    }

    func stopPlaying() {
        print("stop")
        if !isPlaying { return }
        isPlaying = false

        AudioQueueStop(audioQueue!, true)
        AudioQueueDispose(audioQueue!, true)
        audioQueue = nil
        audioQueueBuffers = [nil, nil, nil, nil]
        if let audioFile = audioFile {
            AudioFileClose(audioFile)
        }
        audioFile = nil
    }
}
