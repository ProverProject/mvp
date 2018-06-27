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
    private var currentDeviceOrientation = UIDeviceOrientation.portrait
    private var cameraAvailable: Bool
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var defaultAVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait

    private var captureSession: AVCaptureSession!
    private var captureSessionLoaded = false
    
    private var parentView: UIView

    private let dataOutputQueue = DispatchQueue(label: "DataOutputQueue")
    private var isAssetWriterSessionStarted = false

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
    
    private var running = false
    
    private let videoFileURL =
            FileManager.default.temporaryDirectory.appendingPathComponent("recorded_video.mp4")
    
    // MARK: - Initiallization
    init(withParent parent: UIView) {
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        parentView = parent
        super.init()
    }
}

// MARK: - Public methods
extension VideoRecorder {
    
    @objc func startCapture() {
        guard !running else { return }
        running = true
        
        if !Thread.isMainThread {
            performSelector(onMainThread: #selector(startCapture), with: nil, waitUntilDone: false)
        }
        if cameraAvailable { startCaptureSession() }
    }
    
    func stopCapture() {
        
        guard running else { return }
        running = false
        
        guard let captureSession = captureSession else { return }
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        captureSession.stopRunning()

        captureVideoPreviewLayer?.removeFromSuperlayer()
        captureVideoPreviewLayer = nil

        captureSessionLoaded = false
        
        stopRecord()
    }
    
    func pause() {
        running = false
        captureSession?.stopRunning()
    }
}

// MARK: - Private methods
private extension VideoRecorder {
    
    func startCaptureSession() {
        
        guard cameraAvailable, !captureSessionLoaded else { return }

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

        addVideoPreviewLayer()
        
        captureSessionLoaded = true
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

        // set default video orientation
        if (captureVideoDataOutput.connection(with: .video)?.isVideoOrientationSupported)! {
            captureVideoDataOutput.connection(with: .video)?.videoOrientation = defaultAVCaptureVideoOrientation
        }

        // create a serial dispatch queue used for the sample buffer delegate as well as when
        // a still image is captured a serial dispatch queue must be used to guarantee that
        // video frames will be delivered in order see the header doc for
        // setSampleBufferDelegate:queue: for more information
        //let dataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }

    func addCaptureAudioDataOutput() {
        let captureAudioDataOutput = AVCaptureAudioDataOutput()

        if captureSession.canAddOutput(captureAudioDataOutput) {
            captureSession.addOutput(captureAudioDataOutput)
        }
        captureAudioDataOutput.connection(with: .audio)?.isEnabled = true

        //let dataOutputQueue = DispatchQueue(label: "AudioDataOutputQueue")
        captureAudioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
    }

    func addVideoPreviewLayer() {
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        if (captureVideoPreviewLayer?.connection?.isVideoOrientationSupported)! {
            captureVideoPreviewLayer?.connection?.videoOrientation = defaultAVCaptureVideoOrientation
        }
        
        captureVideoPreviewLayer?.frame = parentView.frame
        
        captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
        parentView.layer.addSublayer(captureVideoPreviewLayer!)
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

        } catch {
            print("[VideoRecorder] Camera unable to create AVAssetWriter: \(error.localizedDescription)")
        }
    }

    func stopRecord(handler: @escaping (URL) -> Void = {_ in }) {
        if assetWriter != nil {
            if assetWriter.status == .writing {
                assetWriter.finishWriting { [unowned self] in
                    handler(self.videoFileURL)
                }
            } else {
                print("[VideoRecorder] Recording Error: asset writer status is not writing")
            }
            assetWriter = nil
        }
        assetWriterInputPixelBufferAdaptor = nil
        assetVideoWriterInput = nil
        assetAudioWriterInput = nil
        isAssetWriterSessionStarted = false
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
        let isRecording = assetWriter != nil && assetWriter.status == .writing

        if isRecording {
            if (!isAssetWriterSessionStarted) {
                assetWriter.startSession(atSourceTime: sourceSampleTimeStamp)
                isAssetWriterSessionStarted = true
            }
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
