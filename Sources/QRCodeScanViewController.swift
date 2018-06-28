//
//  ScanQRCodeControllerViewController.swift
//  smk
//
//  Created by Charles on 24/02/2017.
//  Copyright © 2017 Matrix. All rights reserved.
//

import UIKit

/// 扫描二维码控制器
public class QRCodeScanViewController: UIViewController {
    
    public typealias SuccessCallback = (_ QRCodeInfo: String) -> Void
    
    public init(builder: QRCodeReaderViewBuilder) {
        codeReader = builder.reader
        readerView = builder.readerView
        super.init(nibName: nil, bundle: nil)
    }
    
    public var didFindCode: ((QRCodeReaderResult) -> Void)? {
        set {
            codeReader.didFindCode = newValue
        }
        
        get {
            return codeReader.didFindCode
        }
    }
    
    public var didFailDecoding: (() -> Void)? {
        set {
            codeReader.didFailDecoding = newValue
        }
        
        get {
            return codeReader.didFailDecoding
        }
    }
    
    private var codeReader: QRCodeReader
    private var readerView: UIView?
    
    required public init?(coder aDecoder: NSCoder) {
        self.codeReader = QRCodeReader()
        super.init(coder: aDecoder)
    }
    
    
    /// 扫描成功回调
    public var succeessCallback: SuccessCallback?
    
    // MARK:-  life cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        readerView?.frame = self.view.bounds
        view.addSubview(readerView!)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        codeReader.startScanning()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        codeReader.stopScanning()
    }

}
