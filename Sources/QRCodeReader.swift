//
//  QRCodeReader.swift
//  BaseTools
//
//  Created by Charles on 12/10/2017.
//  Copyright © 2017 Charles. All rights reserved.
//

import UIKit
import AVFoundation

/// 读取器 封装 扫描二维码功能 （纯功能：自定义扫描二维码页面时，单独使用本功能）
public class QRCodeReader: NSObject {
    
    // MARK:- private
    private let sessionQueue  = DispatchQueue(label: "session queue")
    private let metadataObjectsQueue = DispatchQueue(label: "com.pygeeks.qr", attributes: [], target: nil)
    
    /// 默认 后置摄像头
    private var defaultDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video)
    /// 前置摄像头
    private var frontDevice: AVCaptureDevice? = {
        if #available(iOS 10, *) {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        } else {
            for device in AVCaptureDevice.devices(for: .video) {
                if device.position == .front {
                    return device
                }
            }
        }
        return nil
    }()
    
    /// 默认摄像头 input
    lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
        guard let defaultDevice = defaultDevice else { return nil }
        
        return try? AVCaptureDeviceInput(device: defaultDevice)
    }()
    
    /// 前置摄像头 input
    lazy var frontDeviceInput: AVCaptureDeviceInput? = {
        if let _frontDevice = self.frontDevice {
            return try? AVCaptureDeviceInput(device: _frontDevice)
        }
        
        return nil
    }()
    
    var session               = AVCaptureSession()
    
    // MARK:- public
    public var metadataOutput = AVCaptureMetadataOutput()
    public lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        return AVCaptureVideoPreviewLayer(session: self.session)
    }()
    /// metadataObjectTypes 类型
    public let metadataObjectTypes: [AVMetadataObject.ObjectType]
    
    // MARK:- 控制设置
    /// 扫描到二维码后 停止扫描
    public var stopScanningWhenCodeIsFound: Bool = true
    
    /// 扫描到数据之后的回调
    public var didFindCode: ((QRCodeReaderResult) -> Void)?
    
    /// 扫描失败回调
    public var didFailDecoding: (() -> Void)?
    
    // MARK:- 构造函数
    public init(metadataObjectTypes types: [AVMetadataObject.ObjectType], captureDevicePosition: AVCaptureDevice.Position) {
        metadataObjectTypes = types
        super.init()
        sessionQueue.async {
            self.configureDefaultComponents(withCaptureDevicePosition: captureDevicePosition)
        }
    }
    
    public convenience override init() {
        self.init(metadataObjectTypes: [AVMetadataObject.ObjectType.qr], captureDevicePosition: .back)
    }
    
    public convenience init(metadataObjectTypes types: [AVMetadataObject.ObjectType]) {
        self.init(metadataObjectTypes: types, captureDevicePosition: .back)
    }
    
    public convenience init(captureDevicePosition position: AVCaptureDevice.Position) {
        self.init(metadataObjectTypes: [AVMetadataObject.ObjectType.qr], captureDevicePosition: position)
    }
    
    // MARK:- 配置 AV 控件
    private func configureDefaultComponents(withCaptureDevicePosition: AVCaptureDevice.Position) {
        for output in session.outputs {
            session.removeOutput(output)
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // 添加 video input
        switch withCaptureDevicePosition {
        case .front:
            if let _frontDeviceInput = frontDeviceInput {
                session.addInput(_frontDeviceInput)
            }
        case .back, .unspecified:
            if let _defaultDeviceInput = defaultDeviceInput {
                session.addInput(_defaultDeviceInput)
            }
        }
        
        // 添加 metadata output
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes//metadataObjectTypes
        previewLayer.videoGravity          = .resizeAspectFill
        
        session.commitConfiguration()
    }
    
    
    /// 切换前后摄像头
    ///
    /// - Returns: 输入设备（摄像头）
    @discardableResult
    public func switchDeviceInput() -> AVCaptureDeviceInput? {
        if let _frontDeviceInput = frontDeviceInput {
            session.beginConfiguration()
            
            if let _currentInput = session.inputs.first as? AVCaptureDeviceInput {
                session.removeInput(_currentInput)
                
                let newDeviceInput = (_currentInput.device.position == .front) ? defaultDeviceInput : _frontDeviceInput
                session.addInput(newDeviceInput!)
            }
            
            session.commitConfiguration()
        }
        
        return session.inputs.first as? AVCaptureDeviceInput
    }
    
    // MARK: - 状态信息
    /// 是否扫描
    public var isRunning: Bool {
        return session.isRunning
    }
    
    /// 是否拥有前置摄像设备
    public var hasFrontDevice: Bool {
        return frontDevice != nil
    }
    
    /// 是否有闪光灯
    public var isTorchAvailable: Bool {
        return defaultDevice?.isTorchAvailable ?? false
    }

}

// MARK:- reader 控制方法
extension QRCodeReader {
    
    /// 开始扫描二维码
    public func startScanning() {
        if !session.isRunning {
            sessionQueue.async {
                self.session.startRunning()
            }
        }
    }
    
    /// 停止扫描二维码
    public func stopScanning() {
        if session.isRunning {
            sessionQueue.async {
                self.session.stopRunning()
            }
        }
    }
    
    /// 默认device 上闪光灯切换
    public func toggleTorch() {
        do {
            try defaultDevice?.lockForConfiguration()
            
            defaultDevice?.torchMode = defaultDevice?.torchMode == .on ? .off : .on
            
            defaultDevice?.unlockForConfiguration()
        }
        catch _ { }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate 在这里处理扫描结果
extension QRCodeReader: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for current in metadataObjects {
            if let _readableCodeObject = current as? AVMetadataMachineReadableCodeObject {
                if _readableCodeObject.stringValue != nil {
                    if metadataObjectTypes.contains(_readableCodeObject.type) {
                        if let sVal = _readableCodeObject.stringValue {
                            if stopScanningWhenCodeIsFound {
                                stopScanning()
                            }
                            
                            let scannedResult = QRCodeReaderResult(value: sVal, metadataType:_readableCodeObject.type.rawValue)
                            
                            DispatchQueue.main.async(execute: { [weak self] in
                                self?.didFindCode?(scannedResult)
                            })
                        }
                    }
                }
                else {
                    didFailDecoding?()
                }
            }
        }
    }
}

// MARK: - 静态方法 横竖屏旋转控制/reader 是否可用/是否支持metadataTypes
extension QRCodeReader {
    /// 横竖屏切换控制
    ///
    /// - Parameters:
    ///   - orientation: 方向
    ///   - supportedOrientations: 支持的方向
    ///   - fallbackOrientation: fallbackOrientation
    /// - Returns: AVCaptureVideoOrientation
    public class func videoOrientation(deviceOrientation orientation: UIDeviceOrientation, withSupportedOrientations supportedOrientations: UIInterfaceOrientationMask, fallbackOrientation: AVCaptureVideoOrientation? = nil) -> AVCaptureVideoOrientation {
        let result: AVCaptureVideoOrientation
        
        switch (orientation, fallbackOrientation) {
        case (.landscapeLeft, _):
            result = .landscapeRight
        case (.landscapeRight, _):
            result = .landscapeLeft
        case (.portrait, _):
            result = .portrait
        case (.portraitUpsideDown, _):
            result = .portraitUpsideDown
        case (_, .some(let orientation)):
            result = orientation
        default:
            result = .portrait
        }
        
        if supportedOrientations.contains(orientationMask(videoOrientation: result)) {
            return result
        }
        else if let orientation = fallbackOrientation , supportedOrientations.contains(orientationMask(videoOrientation: orientation)) {
            return orientation
        }
        else if supportedOrientations.contains(.portrait) {
            return .portrait
        }
        else if supportedOrientations.contains(.landscapeLeft) {
            return .landscapeLeft
        }
        else if supportedOrientations.contains(.landscapeRight) {
            return .landscapeRight
        }
        else {
            return .portraitUpsideDown
        }
    }
    
    class func orientationMask(videoOrientation orientation: AVCaptureVideoOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        }
    }
    
    /// reader 是否可用
    ///
    /// - Returns: bool
    public class func isAvailable() -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return false }
        
        return (try? AVCaptureDeviceInput(device: captureDevice)) != nil
    }
    
    /// 检查 reader 是否支持某些类型metadataTypes
    ///
    /// - Parameter metadataTypes: 类型
    /// - Returns: 是否支持 bool
    /// - Throws: 异常
    public class func supportsMetadataObjectTypes(_ metadataTypes: [AVMetadataObject.ObjectType]? = nil) throws -> Bool {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw NSError(domain: "com.pygeeks.qrcode", code: -1001, userInfo: nil)
        }
        
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        let output      = AVCaptureMetadataOutput()
        let session     = AVCaptureSession()
        
        session.addInput(deviceInput)
        session.addOutput(output)
        
        var metadataObjectTypes = metadataTypes
        
        if metadataObjectTypes == nil || metadataObjectTypes?.count == 0 {
            // Check the QRCode metadata object type by default
            metadataObjectTypes = [.qr]
        }
        
        for metadataObjectType in metadataObjectTypes! {
            if !output.availableMetadataObjectTypes.contains { $0 == metadataObjectType } {
                return false
            }
        }
        
        return true
    }
}
