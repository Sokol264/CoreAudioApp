//
//  AudioManager.swift
//  AudioCoreApp
//
//  Created by Данил Соколов on 14.09.2024.
//

import AudioToolbox

class AudioRecorder {
    @Published var isRecording = false

    private(set) var audioAmplitudes: [Float] = []
    private(set) var duration: Float?

    private let fileURL: URL = {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("recordedAudio.caf")
    }()

    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = [nil, nil, nil]
    private var audioFile: AudioFileID?
    private var currentByte: Int64 = 0

    private let bufferSize: UInt32 = 1024

    private var audioFormat = AudioStreamBasicDescription(
        mSampleRate: 44100.0,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
        mBytesPerPacket: 2,
        mFramesPerPacket: 1,
        mBytesPerFrame: 2,
        mChannelsPerFrame: 1,
        mBitsPerChannel: 16,
        mReserved: 0
    )

    var handleAudioQueueInput: AudioQueueInputCallback = { (inUserData, inAQ, inBuffer, _, _, _) in
        let audioRecorder = Unmanaged<AudioRecorder>.fromOpaque(inUserData!).takeUnretainedValue()

        guard audioRecorder.isRecording else { return }

        guard let audioFile = audioRecorder.audioFile else { return }

        var ioNumBytes = inBuffer.pointee.mAudioDataBytesCapacity

        audioRecorder.countingAmplitudes(inBuffer: inBuffer)

        guard AudioFileWriteBytes(
            audioFile,
            false,
            audioRecorder.currentByte,
            &ioNumBytes,
            inBuffer.pointee.mAudioData
        ) == noErr else {
            print("Error writing to audio file while recording")
            return
        }
        
        audioRecorder.currentByte += Int64(ioNumBytes)

        guard AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil) == noErr else {
            print("Failed to enqueue buffer while recording")
            return
        }
    }
}

extension AudioRecorder {
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        setupAudioQueue()

        AudioQueueStart(audioQueue!, nil)
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        guard let audioQueue else {
            print("Can't stop recording: AudioQueue is nil")
            return
        }

        var timeLine: AudioQueueTimelineRef?
        if AudioQueueCreateTimeline(audioQueue, &timeLine) == noErr {

            var timeStamp = AudioTimeStamp()
            AudioQueueGetCurrentTime(audioQueue, timeLine, &timeStamp, nil);
            duration = Float(timeStamp.mSampleTime) / Float(audioFormat.mSampleRate)
        }

        guard AudioQueueStop(audioQueue, true) == noErr else {
            print("Can't stop input AudioQueue")
            return
        }

        guard AudioQueueDispose(audioQueue, true) == noErr else {
            print("Can't dispose input AudioQueue")
            return
        }

        self.audioQueue = nil

        currentByte = 0
        audioQueueBuffers = [nil, nil, nil]

        guard let audioFile else {
            print("Can't stop recording: AudioFile is nil")
            return
        }

        guard AudioFileClose(audioFile) == noErr else {
            print("Can't close file while recording")
            return
        }

        self.audioFile = nil
    }
}

private extension AudioRecorder {
    func setupAudioQueue() {
        guard AudioFileCreateWithURL(
            fileURL as CFURL,
            kAudioFileCAFType,
            &audioFormat,
            .eraseFile,
            &audioFile
        ) == noErr else {
            print("Failed file creation while recording")
            return
        }

        let userData = Unmanaged.passUnretained(self).toOpaque()

        guard AudioQueueNewInput(
            &audioFormat,
            handleAudioQueueInput,
            userData,
            nil,
            nil,
            0,
            &audioQueue
        ) == noErr else {
            print("Failed creation input AudioQueue")
            return
        }

        guard let audioQueue else {
            print("Failed: AudioQueue is nil after creation")
            return
        }

        for i in 0..<audioQueueBuffers.count {
            guard AudioQueueAllocateBuffer(
                audioQueue,
                bufferSize,
                &audioQueueBuffers[i]
            ) == noErr else {
                print("Failed allocate buffer while recording")
                return
            }

            if let buffer = audioQueueBuffers[i] {
                guard AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil) == noErr else {
                    print("Failed enqueue buffer while recording")
                    return
                }
            }
        }
    }

    func countingAmplitudes(inBuffer: AudioQueueBufferRef) {
        let audioData = inBuffer.pointee.mAudioData.assumingMemoryBound(to: Int16.self)
        let frameCount = inBuffer.pointee.mAudioDataByteSize / 2

        var amplitudeSum: Float = 0

        for frame in 0..<Int(frameCount) {
            let sampleValue = Float(audioData[frame]) / Float(Int16.max)
            amplitudeSum += sampleValue
        }

        audioAmplitudes.append(amplitudeSum)
    }
}
