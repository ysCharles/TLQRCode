//
//  DefaultReaderView.swift
//  BaseTools
//
//  Created by Charles on 13/10/2017.
//  Copyright © 2017 Charles. All rights reserved.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

let ratio = SCREEN_WIDTH / 320.0 //以iphone5为基础 坐标都以iphone5为基准 进行代码的适配
//尺寸
let kBgImgX = 45 * ratio
let kBgImgY = (64+60) * ratio
let kBgImgWidth = 230 * ratio
let kScrollLineHeight = 20 * ratio

let kTipHeight = 40 * ratio
let kTipY = kBgImgY + kBgImgWidth + kTipHeight

let kBgAlpha: CGFloat = 0.6

let bgImg_img   = "scanBackground"
let Line_img    = "scanLine"
class DefaultReaderView: UIView {
    
    public init(reader: QRCodeReader, frame: CGRect) {
        self.reader = reader
        super.init(frame: frame)
        setUpView()
    }
    
    public init(reader: QRCodeReader) {
        self.reader = reader
        super.init(frame: CGRect.zero)
        setUpView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpView()
    }
    
    // MARK:- 重新计算尺寸
    override func layoutSubviews() {
        super.layoutSubviews()
        coverView?.frame = self.bounds
        
        // 设置中空区域，即有效扫描区域(中间扫描区域透明度比周边要低的效果)
        let rectPath: UIBezierPath = UIBezierPath(rect: self.bounds)
        rectPath.append(UIBezierPath(roundedRect: CGRect(x:kBgImgX, y:kBgImgY, width:kBgImgWidth, height:kBgImgWidth), cornerRadius: 1).reversing())
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = rectPath.cgPath
        coverView?.layer.mask = shapeLayer
        
        reader?.previewLayer.frame = self.bounds
        self.tip.frame = CGRect(x: kBgImgX, y: kTipY, width: kBgImgWidth, height: kTipHeight)
        self.scrollLine.frame = CGRect(x: kBgImgX, y: kBgImgY, width: kBgImgWidth, height: kScrollLineHeight)
        self.bgImg.frame = CGRect(x: kBgImgX, y: kBgImgY, width: kBgImgWidth, height: kBgImgWidth)
    }
    
    // MARK:- 页面布局
    private var coverView: UIView?
    private func setUpView() {
        self.backgroundColor = UIColor.black.withAlphaComponent(kBgAlpha)
        if let reader = self.reader {
            self.layer.insertSublayer(reader.previewLayer, at: 0)
            // 设置有效扫描区域，默认整个图层(很特别，1、要除以屏幕宽高比例，2、其中x和y、width和height分别互换位置)
            let rect = CGRect(x: kBgImgY / SCREEN_HEIGHT, y: kBgImgX / SCREEN_WIDTH, width: kBgImgWidth / SCREEN_HEIGHT, height: kBgImgWidth / SCREEN_WIDTH)
            reader.metadataOutput.rectOfInterest = rect
        }
        
        // 设置中空区域，即有效扫描区域(中间扫描区域透明度比周边要低的效果)
        let maskView = UIView()
        maskView.backgroundColor = UIColor.black.withAlphaComponent(kBgAlpha)
        addSubview(maskView)
        coverView = maskView
        
        //1.添加一个可见的扫描有效区域的框（这里直接是设置一个背景图片）
        addSubview(self.bgImg)
        //2.添加一个上下循环运动的线条（这里直接是添加一个背景图片来运动）
        addSubview(self.scrollLine)
        //3.添加其他有效控件
        addSubview(self.tip)
        
        self.link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    private weak var reader: QRCodeReader?
    
    deinit {
        self.link.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    // MARK:- 属性
    /// 计时器
    private lazy var link: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(LineAnimation))
        return link
    }()
    
    /// 实际有效扫描区域的背景图(亦或者自己设置一个边框)
    private lazy var bgImg: UIImageView = {
        let bgImg = UIImageView()
        bgImg.image = UIImage(named: bgImg_img, in: Bundle(for: self.classForCoder), compatibleWith: nil)
        return bgImg
    }()
    
    /// 有效扫描区域循环往返的一条线（这里用的是一个背景图）
    private lazy var scrollLine: UIImageView = {
        let scrollLine = UIImageView()
        scrollLine.image = UIImage(named: Line_img, in: Bundle(for: self.classForCoder), compatibleWith: nil)
        return scrollLine
    }()
    
    /// 扫码有效区域外自加的文字提示
    private lazy var tip: UILabel = {
        let tip = UILabel()
        tip.text = "自动扫描框内二维码"
        tip.numberOfLines = 0
        tip.textColor = UIColor.white
        tip.textAlignment = .center
        tip.font = UIFont.systemFont(ofSize: 14)
        return tip
    }()
    
    /// 用于记录scrollLine的上下循环状态
    private var up = false
    
    // MARK:- 线条运动的动画
    @objc func LineAnimation() {
        if up {
            var y = self.scrollLine.frame.origin.y
            y += 2
            var rect = self.scrollLine.frame
            rect.origin.y = y
            self.scrollLine.frame = rect
            if y >= kBgImgY + kBgImgWidth - kScrollLineHeight {
                up = false
            }
        } else {
            var y = self.scrollLine.frame.origin.y
            y -= 2
            var rect = self.scrollLine.frame
            rect.origin.y = y
            self.scrollLine.frame = rect
            if y <= kBgImgY {
                up = true
            }
        }
    }
}
