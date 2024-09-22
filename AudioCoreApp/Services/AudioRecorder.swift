//
//  AudioManager.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 14.09.2024.
//

import CoreAudioKit

//final class AudioRecorder {
//    @Published var isRecording: Bool = false
//    var audioFile: AudioFileID?
//
//    private var audioQueue: AudioQueueRef?
//    private var bufferSize: UInt32 = 1024 * 8
//    private var currentPacket: Int64 = 0
//
//    private var audioFormat = AudioStreamBasicDescription(
//        mSampleRate: 44100.0,
//        mFormatID: kAudioFormatLinearPCM,
//        mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
//        mBytesPerPacket: 2,
//        mFramesPerPacket: 1,
//        mBytesPerFrame: 2,
//        mChannelsPerFrame: 1,
//        mBitsPerChannel: 16,
//        mReserved: 0
//    )
//
//    private let audioQueueInputCallback: AudioQueueInputCallback = { (
//        inUserData,
//        inAQ,
//        inBuffer,
//        inStartTime,
//        inNumPackets,
//        inPacketDesc) in
//
//        let audioQueueRecorder = Unmanaged<AudioRecorder>.fromOpaque(inUserData!).takeUnretainedValue()
//
//        guard let audioFile = audioQueueRecorder.audioFile else { return }
//
//        if inNumPackets > 0 {
//            var numPackets = inNumPackets // Make a mutable copy of inNumPackets
//            let status = AudioFileWritePackets(audioFile, false, inBuffer.pointee.mAudioDataByteSize, inPacketDesc, audioQueueRecorder.currentPacket, &numPackets, inBuffer.pointee.mAudioData)
//            if status == noErr {
//                audioQueueRecorder.currentPacket += Int64(numPackets)
//            } else {
//                print("Failed to write packets: \(status)")
//            }
//        }
//
//        // Only enqueue buffer if recording is still active
//        if audioQueueRecorder.isRecording {
//            let status = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
//            guard status == noErr else {
//                print("Failed to enqueue buffer: \(status)")
//                return
//            }
//        }
//    }
//}

//extension AudioRecorder {
//    func setupAudioQueue(filePath: URL) {
//        var status = AudioFileCreateWithURL(
//            filePath as CFURL,
//            kAudioFileCAFType,
//            &audioFormat,
//            .eraseFile,
//            &audioFile
//        )
//
//        guard status == noErr, let _ = audioFile else {
//            print("Не удалось создать аудиофайл: \(status)")
//            return
//        }
//
//        status = AudioQueueNewInput(
//            &audioFormat,
//            audioQueueInputCallback,
//            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
//            nil,
//            nil,
//            0,
//            &audioQueue
//        )
//
//        guard status == noErr,
//            let audioQueue = audioQueue else {
//            print("Failed to create audio queue: \(status)")
//            return
//        }
//
//        for _ in 0..<3 {
//            var buffer: AudioQueueBufferRef?
//            status = AudioQueueAllocateBuffer(audioQueue, bufferSize, &buffer)
//            guard status == noErr, let buffer = buffer else {
//                print("Failed to allocate buffer: \(status)")
//                return
//            }
//
//            status = AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil)
//            guard status == noErr else {
//                print("Failed to enqueue buffer: \(status)")
//                return
//            }
//        }
//
//        print("Audio queue initialized successfully")
//    }
//
//    func startRecording() {
//        guard let audioQueue else {
//            print("Error")
//            return
//        }
//
//        let status = AudioQueueStart(audioQueue, nil)
//        guard status == noErr else {
//            print("Can't start audio recording \(status)")
//            return
//        }
//
//        print("Recording Start!")
//    }
//
//    func stopRecording() {
//        guard let audioQueue else {
//            print("Error")
//            return
//        }
//
//        let status = AudioQueueStop(audioQueue, true)
//        guard status == noErr else {
//            print("Can't stop audio recording \(status)")
//            return
//        }
//
//        AudioQueueDispose(audioQueue, true)
//        if let audioFile {
//            AudioFileClose(audioFile)
////            self.audioFile = nil
//        }
//        self.audioQueue = nil
//
//        print("Recording Stop!")
//    }
//}

import AudioToolbox

class AudioRecorder {
    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = [nil, nil, nil, nil]
    private var audioFile: AudioFileID?
    private var isRecording = false
    private var currentByte: Int64 = 0

    private let sampleRate: Double = 44100.0
    private let bufferSize: UInt32 = 2048

    private let fileURL: URL = {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("recordedAudio.caf")
    }()
    
    var handleAudioQueueInput: AudioQueueInputCallback = { (inUserData,
                                                            inAQ,
                                                            inBuffer,
                                                            inStartTime,
                                                            inNumPackets,
                                                            inPacketDesc) in
        // Приведение inUserData к типу AudioRecorder
        let audioRecorder = Unmanaged<AudioRecorder>.fromOpaque(inUserData!).takeUnretainedValue()

        guard let audioFile = audioRecorder.audioFile else { return }

        // Обработка входных данных
        var ioNumBytes = inBuffer.pointee.mAudioDataBytesCapacity
        let status = AudioFileWriteBytes(
            audioRecorder.audioFile!,
            false,
            audioRecorder.currentByte,
            &ioNumBytes,
            inBuffer.pointee.mAudioData
        )
        if status != noErr {
            print("Error writing to audio file: \(status)")
        }
        
        audioRecorder.currentByte += Int64(ioNumBytes)
        
        if audioRecorder.isRecording {
            let status = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
            guard status == noErr else {
                print("Failed to enqueue buffer: \(status)")
                return
            }
        }
    }
        
    private func setupAudioQueue() {
        setupAudioFile()

        var audioFormat = AudioStreamBasicDescription()
        audioFormat.mSampleRate = sampleRate
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        audioFormat.mBytesPerPacket = 2
        audioFormat.mFramesPerPacket = 1
        audioFormat.mBytesPerFrame = 2
        audioFormat.mChannelsPerFrame = 1
        audioFormat.mBitsPerChannel = 16
        audioFormat.mReserved = 0

        // Преобразование self в UnsafeMutableRawPointer
        let userData = Unmanaged.passUnretained(self).toOpaque()

        // Создание AudioQueue с указателем на функцию C
        guard AudioQueueNewInput(
            &audioFormat,
            handleAudioQueueInput,
            userData,
            nil,
            nil,
            0,
            &audioQueue
        ) == noErr else {
            print("Failed creation input queue")
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
                guard AudioQueueEnqueueBuffer(audioQueue!, buffer, 0, nil) == noErr else {
                    print("Failed enqueue buffer")
                    return
                }
            }
        }
        
        print("Audio queue initialized successfully")
    }

    private func setupAudioFile() {
        let fileURL = self.fileURL as CFURL
        var audioFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )

        guard AudioFileCreateWithURL(
            fileURL,
            kAudioFileCAFType,
            &audioFormat,
            .eraseFile,
            &audioFile
        ) == noErr else {
            print("Failed file creation")
            return
        }
    }

    func startRecording() {
        setupAudioQueue()
        if isRecording { return }
        isRecording = true
        AudioQueueStart(audioQueue!, nil)
        print("Recording !")
    }

    func stopRecording() {
        if !isRecording { return }
        isRecording = false
        AudioQueueStop(audioQueue!, true)
        AudioQueueDispose(audioQueue!, true)
        if let audioFile = audioFile {
            AudioFileClose(audioFile)
        }

        self.audioQueue = nil

        print("Recording Stop!")
    }
}
