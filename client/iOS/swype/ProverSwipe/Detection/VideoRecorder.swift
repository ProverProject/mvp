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
    
    private var defaultFPS = 30
    
    private var parentView: UIView

    private var assetWriterInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var assetWriter: AVAssetWriter?
    
    // MARK: - Dependencies
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd__HH-mm-ss"
        return formatter
    }()
    
    private var recordingCountDown = 5
    private var isRecording = false
    private var running = false
    
    private let videoFileURL =
            FileManager.default.temporaryDirectory.appendingPathComponent("video_track.mp4")
    
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

        addCaptureDeviceInput()
        addCaptureVideoDataOutput()

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
    
    func addCaptureDeviceInput() {
        
        let discoverySession = AVCaptureDevice
            .DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                              mediaType: .video,
                              position: .back)
        
        let captureDevice = discoverySession.devices.first!
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            // support for autofocus
            if captureDevice.isFocusModeSupported(.autoFocus) {
                try captureDevice.lockForConfiguration()
                captureDevice.focusMode = .autoFocus
                captureDevice.unlockForConfiguration()
            }
            
            for oldInput in captureSession.inputs {
                captureSession.removeInput(oldInput)
            }

            if (captureSession.canAddInput(captureDeviceInput)) {
                captureSession.addInput(captureDeviceInput)
            }
            else {
                print("[VideoRecorder] Could not add the device input to capture session!")
            }
        } catch {
            print("[VideoRecorder] Error when creating capture device \(error.localizedDescription)")
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
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
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
        isRecording = true

        // Video File Output in H.264, via AVAsserWriter
        var outputSettings = [AVVideoWidthKey: 720,
                              AVVideoHeightKey: 1280] as [String: Any]

        if #available(iOS 11.0, *) {
            outputSettings[AVVideoCodecKey] = AVVideoCodecType.h264
        } else {
            outputSettings[AVVideoCodecKey] = AVVideoCodecH264
        }

        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)

        let pixelBufferFormat = kCVPixelFormatType_32BGRA
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String: pixelBufferFormat]

        assetWriterInputPixelBufferAdaptor =
                AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput!,
                        sourcePixelBufferAttributes: attributes)

        do {
            assetWriter = try AVAssetWriter(url: videoFileURL, fileType: .mp4)
            assetWriter!.add(assetWriterInput!)
            assetWriterInput!.expectsMediaDataInRealTime = true

        } catch {
            print("[VideoRecorder] Camera unable to create AVAssetWriter: \(error.localizedDescription)")
        }
    }

    func stopRecord(handler: @escaping (URL) -> Void = {_ in }) {
        isRecording = false

        if let writer = assetWriter {
            if writer.status == .writing {
                writer.finishWriting { [unowned self] in
                    handler(self.videoFileURL)
                }
            } else {
                print("[VideoRecorder] Recording Error: asset writer status is not writing")
            }
            assetWriter = nil
        }
        assetWriterInput = nil
        assetWriterInputPixelBufferAdaptor = nil
        recordingCountDown = 5
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VideoRecorder: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Sent image buffer to delegate
        if let delegate = delegate {
            delegate.process(buffer: imageBuffer, timestamp: lastSampleTime)
        }
        
        // Save video
        guard isRecording else { return }
        
        recordingCountDown -= 1
        guard recordingCountDown < 0 else {
            return
        }
        
        if assetWriter?.status != .writing {
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: lastSampleTime)
            if assetWriter?.status != .writing {
                let errorDescription = assetWriter?.error?.localizedDescription ?? "unknown error"
                print("[VideoRecorder] Recording Error: asset writer status is not writing: \(errorDescription)")
            }
        }
        
        if assetWriterInput!.isReadyForMoreMediaData {
            let result = assetWriterInputPixelBufferAdaptor!.append(imageBuffer, withPresentationTime: lastSampleTime)
            if !result {
                print("[VideoRecorder] Video Writing Error")
            }
        }
    }
}
