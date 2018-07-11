import UIKit
import Accelerate
import AVFoundation

protocol VideoRecorderDelegate: class {
    func process(buffer: CVImageBuffer, timestamp: CMTime)
}

class VideoRecorder: NSObject {

    private enum RecordingStatus {
        case idle, recording, finishing
    }

    // MARK: - Public properties
    weak var delegate: VideoRecorderDelegate?

    // MARK: - Private properties
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!

    private var captureSession: AVCaptureSession!

    private let dataOutputQueue = DispatchQueue(label: "DataOutputQueue")

    private var recordingStatus: RecordingStatus = .idle
    public var isRecording: Bool { return recordingStatus != .idle }

    private var isAssetWriterSessionStarted = false

    private var assetVideoWriterInput: AVAssetWriterInput!
    private var assetAudioWriterInput: AVAssetWriterInput!

    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    private var assetWriter: AVAssetWriter!

    private var isMicrophoneEnabled: Bool = false

    // MARK: - Dependencies
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd__HH-mm-ss"
        return formatter
    }()
    
    private let videoFileURL =
            FileManager.default.temporaryDirectory.appendingPathComponent("recorded_video.mp4")

    // MARK: - Initialization
    init(withParent parent: VideoPreviewView) {
        super.init()

        captureVideoPreviewLayer = parent.videoPreviewLayer
        captureSession = createCaptureSession()

        captureVideoPreviewLayer.session = captureSession

        captureSession.beginConfiguration()

        addCaptureVideoDeviceInput()
        addCaptureAudioDeviceInput()

        captureSession.commitConfiguration()
    }
}

// MARK: - Public methods
extension VideoRecorder {

    func startSession() {
        captureSession.startRunning()
    }

    func stopSession() {
        captureSession.stopRunning()
    }
}

// MARK: - Private methods
private extension VideoRecorder {

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

        // We MUST have available camera here so aren't catching any exceptions
        let captureVideoDeviceInput = try! AVCaptureDeviceInput(device: captureVideoDevice)

        // support for autofocus
        if captureVideoDevice.isFocusModeSupported(.autoFocus) {
            try! captureVideoDevice.lockForConfiguration()
            captureVideoDevice.focusMode = .autoFocus
            captureVideoDevice.unlockForConfiguration()
        }

        if (captureSession.canAddInput(captureVideoDeviceInput)) {
            captureSession.addInput(captureVideoDeviceInput)
        }
        else {
            print("[VideoRecorder] Could not add the video device input to capture session!")
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

                isMicrophoneEnabled = true
            }
            else {
                print("[VideoRecorder] Could not add the audio device input to capture session!")
            }
        } catch {
            print("[VideoRecorder] Okay, mike is disabled, the video will just be silent: \(error.localizedDescription)")
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

        let connection = captureVideoDataOutput.connection(with: .video)!

        connection.isEnabled = true
        connection.videoOrientation = captureVideoPreviewLayer.connection!.videoOrientation

        captureVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }

    func addCaptureAudioDataOutput() {
        guard isMicrophoneEnabled else {
            return
        }

        let captureAudioDataOutput = AVCaptureAudioDataOutput()

        if captureSession.canAddOutput(captureAudioDataOutput) {
            captureSession.addOutput(captureAudioDataOutput)
        }

        captureAudioDataOutput.connection(with: .audio)?.isEnabled = true
        captureAudioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }
}

// MARK: - Handle device rotation
extension VideoRecorder {
    func viewWillLayoutSubviews() {
        let previewLayerConnection = captureVideoPreviewLayer.connection!

        switch (UIDevice.current.orientation) {
        case .portrait:
            previewLayerConnection.videoOrientation = .portrait
        case .portraitUpsideDown:
            previewLayerConnection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            previewLayerConnection.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewLayerConnection.videoOrientation = .landscapeLeft
        default:
            break
        }
    }
}

// MARK: - Recording
extension VideoRecorder {

    private var assetVideoSettings: [String : Any] {
        var videoCodec: Any

        if #available(iOS 11.0, *) {
            videoCodec = AVVideoCodecType.h264
        } else {
            videoCodec = AVVideoCodecH264
        }

        let assistant = AVOutputSettingsAssistant(preset: Settings.currentVideoPreset)
        let settings = assistant!.videoSettings!
        let settingsWidth = settings[AVVideoWidthKey] as! Int
        let settingsHeight = settings[AVVideoHeightKey] as! Int

        let videoOrientation = captureVideoPreviewLayer.connection!.videoOrientation

        if videoOrientation == .landscapeLeft || videoOrientation == .landscapeRight {
            return [AVVideoWidthKey: settingsWidth,
                    AVVideoHeightKey: settingsHeight,
                    AVVideoCodecKey: videoCodec]
        }
        else {
            return [AVVideoWidthKey: settingsHeight,
                    AVVideoHeightKey: settingsWidth,
                    AVVideoCodecKey: videoCodec]
        }
    }

    private var assetAudioSettings: [String : Any] {
        return [AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1]
    }

    func startRecord() {
        guard recordingStatus == .idle else {
            return
        }

        recordingStatus = .recording

        FileManager.clearTempDirectory()

        assetWriter = try! AVAssetWriter(url: videoFileURL, fileType: .mp4)

        assetVideoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: assetVideoSettings)
        assetVideoWriterInput.expectsMediaDataInRealTime = true

        let videoOutputAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                                   assetWriterInput: assetVideoWriterInput,
                                   sourcePixelBufferAttributes: videoOutputAttributes)

        if assetWriter.canAdd(assetVideoWriterInput) {
            assetWriter.add(assetVideoWriterInput)
        }

        if isMicrophoneEnabled {
            assetAudioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: assetAudioSettings)
            assetAudioWriterInput.expectsMediaDataInRealTime = true

            if assetWriter.canAdd(assetAudioWriterInput) {
                assetWriter.add(assetAudioWriterInput)
            }
        }

        guard assetWriter.startWriting() else {
            print("[VideoRecorder] Recording Error: asset writer could not start writing: \(assetWriter.error?.localizedDescription)")
            return
        }

        captureSession.stopRunning()
        captureSession.beginConfiguration()

        addCaptureVideoDataOutput()

        if isMicrophoneEnabled {
            addCaptureAudioDataOutput()
        }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    func stopRecord(handler: @escaping (URL) -> Void) {
        guard recordingStatus == .recording else {
            return
        }

        recordingStatus = .finishing

        let isNowRunning = captureSession.isRunning

        if isNowRunning {
            captureSession.stopRunning()
        }

        captureSession.beginConfiguration()

        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }

        captureSession.commitConfiguration()

        if isNowRunning {
            captureSession.startRunning()
        }

        isAssetWriterSessionStarted = false

        if assetWriter.status == .writing {
            print("[VideoRecorder] stopRecord(), status is .writing")
            assetWriter.finishWriting { [unowned self] in
                print("[VideoRecorder] stopRecord's completion, status is \(self.assetWriter.status.rawValue)")
                self.disposeAssetWriter()
                handler(self.videoFileURL)
            }
        } else {
            print("[VideoRecorder] stopRecord(), status is *** \(assetWriter.status.rawValue) ***!!!")
            disposeAssetWriter()
            print("[VideoRecorder] Recording Error: asset writer status is not writing")
        }
    }

    private func disposeAssetWriter() {
        assetWriterInputPixelBufferAdaptor = nil
        assetVideoWriterInput = nil
        assetAudioWriterInput = nil
        assetWriter = nil

        recordingStatus = .idle
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

        if !isAssetWriterSessionStarted {
            assetWriter.startSession(atSourceTime: sourceSampleTimeStamp)
            isAssetWriterSessionStarted = true
        }

        switch output {
        case is AVCaptureVideoDataOutput:
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            delegate?.process(buffer: imageBuffer, timestamp: sourceSampleTimeStamp)

            recordVideoImageBuffer(imageBuffer, connection, sourceSampleTimeStamp)

        case is AVCaptureAudioDataOutput:
            recordAudioSampleBuffer(sampleBuffer, connection)

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
