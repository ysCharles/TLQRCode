//
//  QRCodeReaderViewBuilder.swift
//  BaseTools
//
//  Created by Charles on 13/10/2017.
//  Copyright © 2017 Charles. All rights reserved.
//

import UIKit

public class QRCodeReaderViewBuilder {
    public typealias QRCodeReaderViewBuilderBlock = (QRCodeReaderViewBuilder) -> Void
    
    /// 扫描器
    public var reader = QRCodeReader()
    
    /// 扫描界面 可以自定义页面
    public var readerView: UIView
    
    /// 加载完成后是否开始扫描
    public var startScanningAtLoad = true
    
    // MARK: - 构造函数
    public init(readerView: UIView? = nil) {
        if let view = readerView {
            self.readerView = view
        } else {
            self.readerView = DefaultReaderView(reader: self.reader)
        }
    }
    
    /// 可配置构造函数
    ///
    /// - Parameter buildBlock: 构建闭包 再次可以对 reader 进行配置
    public init(readerView: UIView? = nil, buildBlock: QRCodeReaderViewBuilderBlock) {
        if let view = readerView {
            self.readerView = view
        } else {
            self.readerView = DefaultReaderView(reader: self.reader)
        }
        buildBlock(self)
    }
}
