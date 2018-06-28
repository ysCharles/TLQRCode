//
//  QRCodeUtil.swift
//  TLQRCode
//
//  Created by Charles on 2018/6/28.
//  Copyright © 2018 Charles. All rights reserved.
//

import Foundation
import UIKit

public struct QRCodeUtil {
    // MARK:- 生成二维码图片
    /// 生成二维码图片
    ///
    /// - Parameters:
    ///   - qrString: 二维码信息字符串
    ///   - qrImageName: 二维码图片中间的图标（可为空）
    /// - Returns: 二维码图片
    public static func createQRCode(qrString: String?, qrImageName: String?) -> UIImage? {
        if let sureQRString = qrString {
            let stringData = sureQRString.data(using: .utf8, allowLossyConversion: false)
            //创建一个二维码滤镜
            let qrFilter = CIFilter(name: "CIQRCodeGenerator")
            qrFilter!.setValue(stringData, forKey: "inputMessage")
            qrFilter!.setValue("H", forKey: "inputCorrectionLevel")
            let qrCIImage = qrFilter!.outputImage
            
            //创建一个颜色滤镜 黑白色
            let colorFilter = CIFilter(name: "CIFalseColor")
            colorFilter!.setDefaults()
            colorFilter!.setValue(qrCIImage, forKey: "inputImage")
            colorFilter!.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")
            colorFilter!.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")
            
            //返回二维码 image
            let ciImage = colorFilter?.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5))
            guard let ci = ciImage else {
                return nil
            }
            let codeImage = UIImage(ciImage: ci)
            // 通常,二维码都是定制的,中间都会放想要表达意思的图片
            guard let imageName = qrImageName else { return codeImage }
            if let iconImage = UIImage(named:  imageName) {
                let rect = CGRect(x: 0, y: 0, width: codeImage.size.width, height: codeImage.size.height)
                UIGraphicsBeginImageContext(rect.size)
                codeImage.draw(in: rect)
                let avatarSize = CGSize(width:rect.size.width * 0.25,height: rect.size.height * 0.25)
                let x = (rect.width - avatarSize.width) * 0.5
                let y = (rect.height - avatarSize.height) * 0.5
                iconImage.draw(in: CGRect(x: x, y: y, width: avatarSize.width, height: avatarSize.height))
                let resultImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return resultImage
            }
            return codeImage
        }
        return nil
    }
}
