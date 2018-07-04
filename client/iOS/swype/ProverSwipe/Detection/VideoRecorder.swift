import UIKit
import Accelerate
import AVFoundation

protocol VideoRecorderDelegate: class {
    func process(buffer: CVImageBuffer, timestamp: CMTime)
}

class VideoRecorder: NSObject {
    
    // MARK: - Public properties
    weak var delegate: VideoRecorderDelegate?

    // MARK: - Private properties
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!

    private var captureSession: AVCaptureSession!
    
    private let dataOutputQueue = DispatchQueue(label: "DataOutputQueue")
    public var isRecordingAlive: Bool { return assetWriter != nil }
    private var isRecording = false
    private var isRecordingSessionStarted = false

    private var assetVideoWriterInput: AVAssetWriterInput!
    private var assetAudioWriterInput: AVAssetWriterInput!

    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    private var assetWriter: AVAssetWriter!
    
    // MARK: - Dependencies
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd__HH-mm-ss"
        return formatter
    }()
    
    private var isCapturing = false
    
    private let videoFileURL =
            FileManager.default.temporaryDirectory.appendingPathComponent("recorded_video.mp4")
    
    // MARK: - Initialization
    init(withParent parent: VideoPreviewView) {
        captureVideoPreviewLayer = parent.videoPreviewLayer
    }
}

// MARK: - Public methods
extension VideoRecorder {
    
    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        startCaptureSession()
    }
    
    func stopCapture() {
        
        guard isCapturing else { return }
        isCapturing = false
        
        guard let captureSession = captureSession else { return }
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        captureSession.stopRunning()

        captureVideoPreviewLayer.session = nil
        
        stopRecord()
    }
}

// MARK: - Private methods
private extension VideoRecorder {

    func startCaptureSession() {

        captureSession = createCaptureSession()

        captureSession.beginConfiguration()

        for oldInput in captureSession.inputs {
            captureSession.removeInput(oldInput)
        }

        addCaptureVideoDeviceInput()
        addCaptureAudioDeviceInput()

        addCaptureVideoDataOutput()
        addCaptureAudioDataOutput()

        captureSession.commitConfiguration()

        assignVideoPreviewLayerSession()
        
        captureSession.startRunning()
    }
    
    func createCaptureSession() -> AVCaptureSession {
        
        let captureSession = AVCaptureSession()
        // set a av capture session preset
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else if captureSession.canSetSessionPreset(.low) {
            captureSession.sessionPreset = .low
        } else {
            print("[VideoRecorder] Error: could not set session preset")
        }

        return captureSession
    }
    
    func addCaptureVideoDeviceInput() {
        
        let discoverySession = AVCaptureDevice
            .DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                              mediaType: .video,
                              position: .back)
        
        let captureVideoDevice = discoverySession.devices.first!
        
        do {
            let captureVideoDeviceInput = try AVCaptureDeviceInput(device: captureVideoDevice)
            
            // support for autofocus
            if captureVideoDevice.isFocusModeSupported(.autoFocus) {
                try captureVideoDevice.lockForConfiguration()
                captureVideoDevice.focusMode = .autoFocus
                captureVideoDevice.unlockForConfiguration()
            }
            
            if (captureSession.canAddInput(captureVideoDeviceInput)) {
                captureSession.addInput(captureVideoDeviceInput)
            }
            else {
                print("[VideoRecorder] Could not add the video device input to capture session!")
            }
        } catch {
            print("[VideoRecorder] Error when creating capture video device \(error.localizedDescription)")
        }
    }

    func addCaptureAudioDeviceInput() {
        let discoverySession = AVCaptureDevice
                .DiscoverySession(deviceTypes: [.builtInMicrophone],
                mediaType: .audio,
                position: .unspecified)

        let captureAudioDevice = discoverySession.devices.first!

        do {
            let captureAudioDeviceInput = try AVCaptureDeviceInput(device: captureAudioDevice)

            if (captureSession.canAddInput(captureAudioDeviceInput)) {
                captureSession.addInput(captureAudioDeviceInput)
            }
            else {
                print("[VideoRecorder] Could not add the audio device input to capture session!")
            }
        } catch {
            print("[VideoRecorder] Error when creating capture audio device \(error.localizedDescription)")
        }
    }

    func addCaptureVideoDataOutput() {

        // Make a video data output
        let captureVideoDataOutput = AVCaptureVideoDataOutput()

        // In color mode we, BGRA format is used
        let format = Int(kCVPixelFormatType_32BGRA)
        captureVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: format] as [String: Any]

        // discard if the data output queue is blocked (as we process the still image)
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(captureVideoDataOutput) {
            captureSession.addOutput(captureVideoDataOutput)
        }

        captureVideoDataOutput.connection(with: .video)?.isEnabled = true
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)

        if let connection = captureVideoDataOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    func addCaptureAudioDataOutput() {
        let captureAudioDataOutput = AVCaptureAudioDataOutput()

        if captureSession.canAddOutput(captureAudioDataOutput) {
            captureSession.addOutput(captureAudioDataOutput)
        }

        captureAudioDataOutput.connection(with: .audio)?.isEnabled = true
        captureAudioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }

    func assignVideoPreviewLayerSession() {
        captureVideoPreviewLayer.session = captureSession
    }
}

// MARK: - Handle device rotation
extension VideoRecorder {
    func viewWillLayoutSubviews() {
        guard let connection = captureVideoPreviewLayer.connection, connection.isVideoOrientationSupported else {
            return
        }

        switch (UIDevice.current.orientation) {
        case .portrait:
            connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        default:
            break
        }
    }
}

// MARK: - Recording
extension VideoRecorder {

    func startRecord() {
        var videoCodec: Any

        if #available(iOS 11.0, *) {
            videoCodec = AVVideoCodecType.h264
        } else {
            videoCodec = AVVideoCodecH264
        }

        let videoOutputSettings = [AVVideoWidthKey: 720,
                                   AVVideoHeightKey: 1280,
                                   AVVideoCodecKey: videoCodec]

        assetVideoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        assetVideoWriterInput.expectsMediaDataInRealTime = true

        let videoOutputAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                                   assetWriterInput: assetVideoWriterInput,
                                   sourcePixelBufferAttributes: videoOutputAttributes)

        let audioOutputSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                   AVSampleRateKey: 12000,
                                   AVNumberOfChannelsKey: 1]

        assetAudioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        assetAudioWriterInput.expectsMediaDataInRealTime = true

        do {
            FileManager.clearTempDirectory()

            assetWriter = try AVAssetWriter(url: videoFileURL, fileType: .mp4)

            if assetWriter.canAdd(assetVideoWriterInput) {
                assetWriter.add(assetVideoWriterInput)
            }

            if assetWriter.canAdd(assetAudioWriterInput) {
                assetWriter.add(assetAudioWriterInput)
            }

            guard assetWriter.startWriting() else {
                print("[VideoRecorder] Recording Error: asset writer could not start writing: \(assetWriter.error?.localizedDescription)")
                return
            }

            isRecording = true
        } catch {
            print("[VideoRecorder] Camera unable to create AVAssetWriter: \(error.localizedDescription)")
        }
    }

    func stopRecord(handler: @escaping (URL) -> Void = {_ in }) {
        guard isRecording else { return }

        isRecording = false
        isRecordingSessionStarted = false

        if assetWriter.status == .writing {
            print("[VideoRecorder] stopRecord(), status is .writing")
            assetWriter.finishWriting { [unowned self] in
                print("[VideoRecorder] stopRecord's completion, status is \(self.assetWriter.status.rawValue)")
                self.disposeRecord()
                handler(self.videoFileURL)
            }
        } else {
            print("[VideoRecorder] stopRecord(), status is *** \(assetWriter.status.rawValue) ***!!!")
            disposeRecord()
            print("[VideoRecorder] Recording Error: asset writer status is not writing")
        }
    }

    func disposeRecord() {
        assetWriter = nil
        assetWriterInputPixelBufferAdaptor = nil
        assetVideoWriterInput = nil
        assetAudioWriterInput = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoRecorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate  {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            return
        }

        let sourceSampleTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if isRecording && !isRecordingSessionStarted {
            assetWriter.startSession(atSourceTime: sourceSampleTimeStamp)
            isRecordingSessionStarted = true
        }

        switch output {
        case is AVCaptureVideoDataOutput:
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            delegate?.process(buffer: imageBuffer, timestamp: sourceSampleTimeStamp)

            if (isRecording) {
                recordVideoImageBuffer(imageBuffer, connection, sourceSampleTimeStamp)
            }

        case is AVCaptureAudioDataOutput:
            if (isRecording) {
                recordAudioSampleBuffer(sampleBuffer, connection)
            }

        default:
            print("[VideoRecorder] output is neither AVCaptureVideoDataOutput nor AVCaptureAudioDataOutput!")
        }
    }

    fileprivate func recordVideoImageBuffer(_ imageBuffer: CVImageBuffer, _ connection: AVCaptureConnection,
                                            _ sourceSampleTimeStamp: CMTime) {
        if assetVideoWriterInput.isReadyForMoreMediaData {
            guard assetWriterInputPixelBufferAdaptor.append(imageBuffer, withPresentationTime: sourceSampleTimeStamp) else {
                print("[VideoRecorder] Video frame writing Error")
                return
            }
        }
    }

    fileprivate func recordAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, _ connection: AVCaptureConnection) {
        if assetAudioWriterInput.isReadyForMoreMediaData {
            guard assetAudioWriterInput.append(sampleBuffer) else {
                print("[VideoRecorder] Audio frame writing Error")
                return
            }
        }
    }
}
