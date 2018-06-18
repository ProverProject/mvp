import UIKit
import Accelerate
import AVFoundation

protocol VideoRecorderDelegate: class {
    func process(buffer: CVImageBuffer, timestamp: CMTime)
}

class VideoRecorder: NSObject {
    
    // MARK: - Public properties
    weak var delegate: VideoRecorderDelegate?
    var recordVideo = false
    var rotateVideo = false
    
    // MARK: - Private properties
    private var currentDeviceOrientation = UIDeviceOrientation.portrait
    private var cameraAvailable: Bool
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var defaultAVCaptureDevicePosition = AVCaptureDevice.Position.back
    private var defaultAVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    private var defaultAVCaptureSessionPreset = AVCaptureSession.Preset.hd1920x1080
    
    private var captureSession: AVCaptureSession?
    private var captureSessionLoaded = false
    
    private var defaultFPS = 30
    
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?
    
    private var parentView: UIView
    private var customPreviewLayer: CALayer?
    
    private var recordAssetWriterInput: AVAssetWriterInput?
    private var recordPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var recordAssetWriter: AVAssetWriter?
    
    // MARK: - Dependencies
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd__HH-mm-ss"
        return formatter
    }()
    
    private var recordingCountDown = 5
    private var isRecording = false
    private var running = false
    
    private var videoFileURL: URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent("video_track.mp4")
    }
    
    // MARK: - Initiallization
    init(withParent parent: UIView) {
        cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        parentView = parent
        super.init()
    }
}

// MARK: - Public methods
extension VideoRecorder {
    
    @objc func start() {
        guard !running else { return }
        running = true
        
        if !Thread.isMainThread {
            performSelector(onMainThread: #selector(start), with: nil, waitUntilDone: false)
        }
        if cameraAvailable { startCaptureSession() }
    }
    
    func stop() {
        
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
        captureVideoPreviewLayer = nil
        captureSessionLoaded = false
        
        videoDataOutput = nil
        stopRecord()
        
        if let layer = customPreviewLayer {
            layer.removeFromSuperlayer()
            customPreviewLayer = nil
        }
    }
    
    func pause() {
        running = false
        captureSession?.stopRunning()
    }
    
    func startRecord() {
        
        guard recordVideo else { return }
        isRecording = true
        
        createVideoFileOutput()
        
        if FileManager.default.fileExists(atPath: videoFileURL.relativePath) {
            do {
                try FileManager.default.removeItem(at: videoFileURL)
            } catch {
                print("[VideoCamera] FileManager can't delete file at \(videoFileURL)")
            }
        }
    }
    
    func stopRecord(handler: @escaping (URL) -> Void = {_ in }) {
        
        guard recordVideo else { return }
        isRecording = false
        
        if let writter = recordAssetWriter {
            if writter.status == .writing {
                writter.finishWriting { [weak self] in
                    guard let videoFileURL = self?.videoFileURL else { return }
                    handler(videoFileURL)
                }
            } else {
                print("[VideoCamera] Camera Recording Error: asset writer status is not writing")
            }
            recordAssetWriter = nil
        }
        recordAssetWriterInput = nil
        recordPixelBufferAdaptor = nil
        recordingCountDown = 5
    }
}

// MARK: - Private methods
private extension VideoRecorder {
    
    func startCaptureSession() {
        
        guard cameraAvailable, !captureSessionLoaded else { return }
        
        createCaptureSession()
        createCaptureDevice()
        createVideoDataOutput()
        createVideoPreviewLayer()
        
        captureSessionLoaded = true
        captureSession?.startRunning()
    }
    
    func createCaptureSession() {
        
        captureSession = AVCaptureSession()
        // set a av capture session preset
        if captureSession!.canSetSessionPreset(defaultAVCaptureSessionPreset) {
            captureSession!.sessionPreset = defaultAVCaptureSessionPreset
        } else if captureSession!.canSetSessionPreset(.low) {
            captureSession!.sessionPreset = .low
        } else {
            print("[Camera] Error: could not set session preset")
        }
    }
    
    func createCaptureDevice() {
        
        let discoverySession = AVCaptureDevice
            .DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                              mediaType: .video,
                              position: defaultAVCaptureDevicePosition)
        
        let device = discoverySession.devices.first!
        
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            // support for autofocus
            if device.isFocusModeSupported(.autoFocus) {
                try device.lockForConfiguration()
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            }
            
            for oldInput in captureSession.inputs {
                captureSession.removeInput(oldInput)
            }
            
            captureSession.addInput(input)
        } catch {
            print("Error when creating capture device \(error.localizedDescription)")
        }
        
        captureSession.commitConfiguration()
    }
    
    func createVideoDataOutput() {

        guard let captureSession = captureSession else { return }
        
        // Make a video data output
        videoDataOutput = AVCaptureVideoDataOutput()
        
        // In color mode we, BGRA format is used
        let format = Int(kCVPixelFormatType_32BGRA)
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey: format] as [String: Any]
        
        // discard if the data output queue is blocked (as we process the still image)
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoDataOutput!) {
            captureSession.addOutput(videoDataOutput!)
        }
        videoDataOutput?.connection(with: .video)?.isEnabled = true
        
        // set default video orientation
        if (videoDataOutput?.connection(with: .video)?.isVideoOrientationSupported)! {
            videoDataOutput?.connection(with: .video)?.videoOrientation = defaultAVCaptureVideoOrientation
        }
        
        // create a custom preview layer
        customPreviewLayer = CALayer()
        customPreviewLayer?.bounds = CGRect(origin: .zero,
                                            size: parentView.frame.size)
        customPreviewLayer?.position = CGPoint(x: parentView.frame.size.width / 2,
                                               y: parentView.frame.size.height / 2)
        updateOrientation()
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    }
    
    func createVideoPreviewLayer() {
        
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        
        if (captureVideoPreviewLayer?.connection?.isVideoOrientationSupported)! {
            captureVideoPreviewLayer?.connection?.videoOrientation = defaultAVCaptureVideoOrientation
        }
        
        captureVideoPreviewLayer?.frame = parentView.frame
        
        captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
        parentView.layer.addSublayer(captureVideoPreviewLayer!)
    }
    
    func createVideoFileOutput() {

        // Video File Output in H.264, via AVAsserWriter
        var outputSettings = [AVVideoWidthKey: 720,
                              AVVideoHeightKey: 1280] as [String: Any]
        
        if #available(iOS 11.0, *) {
            outputSettings[AVVideoCodecKey] = AVVideoCodecType.h264
        } else {
            outputSettings[AVVideoCodecKey] = AVVideoCodecH264
        }
        
        recordAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let pixelBufferFormat = kCVPixelFormatType_32BGRA
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String: pixelBufferFormat]
        recordPixelBufferAdaptor =
            AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: recordAssetWriterInput!,
                                                 sourcePixelBufferAttributes: attributes)
        
        do {
            recordAssetWriter = try AVAssetWriter(url: videoFileURL, fileType: .mp4)
            recordAssetWriter?.add(recordAssetWriterInput!)
            recordAssetWriterInput?.expectsMediaDataInRealTime = true
  
        } catch {
            print("Camera unable to create AVAssetWriter: \(error.localizedDescription)")
        }
    }
    
    func createCustomVideoPreview() {
        parentView.layer.addSublayer(customPreviewLayer!)
    }
    
    func updateOrientation() {

        guard rotateVideo else { return }
        
        customPreviewLayer?
            .bounds = CGRect(origin: .zero,
                             size: CGSize(width: parentView.frame.size.width,
                                          height: parentView.frame.size.height))
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
        guard recordVideo && recordingCountDown < 0 else {
            return
        }
        
        if recordAssetWriter?.status != .writing {
            recordAssetWriter?.startWriting()
            recordAssetWriter?.startSession(atSourceTime: lastSampleTime)
            if recordAssetWriter?.status != .writing {
                let errorDescription = recordAssetWriter?.error?.localizedDescription ?? "unknown error"
                print("[Camera] Recording Error: asset writer status is not writing: \(errorDescription)")
            }
        }
        
        if recordAssetWriterInput!.isReadyForMoreMediaData {
            let result = recordPixelBufferAdaptor!.append(imageBuffer, withPresentationTime: lastSampleTime)
            if !result {
                print("Video Writing Error")
            }
        }
    }
}
