//
//  Button.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/8.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

//用IBDesignable建立客製化元件
//自定義的類別上寫上IBDesignable告訴Xcode此類別有延伸屬性
@IBDesignable
class Button:UIButton{
    
    @IBInspectable var enableImageRightAligned: Bool = false
    @IBInspectable var enableGradientBackground: Bool = false
    @IBInspectable var gradientColorBlack: UIColor = UIColor.black
    @IBInspectable var gradientColorWhite: UIColor = UIColor.white
    
    //IBInspectable可以告訴Xcode此為延伸屬性
    //預設圓角的弧度為0.0
    @IBInspectable var cornerRedius: Double = 0.0 {
        didSet{
            layer.cornerRadius = CGFloat(cornerRedius)
            //如果給button添加背景，就要加上maskToBounds讓圓角生效
            //masksToBounds是對應到CALayer(for layer)
            //用途為sub view若有超過view的地方，會被擷取
            layer.masksToBounds = true
        }
    }
    
    @IBInspectable var borderWidth: Double = 0.0 {
        didSet {
            layer.borderWidth = CGFloat(borderWidth)
        }
    }

    @IBInspectable var borderColor: UIColor = .black {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    //titleEdgeInset：標題的偏移量
    @IBInspectable var titleLeftPadding: Double = 0.0 {
        didSet {
            titleEdgeInsets.left = CGFloat(titleLeftPadding)
        }
    }
    
    @IBInspectable var titleRightPadding: Double = 0.0 {
           didSet {
               titleEdgeInsets.right = CGFloat(titleRightPadding)
           }
       }

    @IBInspectable var titleTopPadding: Double = 0.0 {
       didSet {
           titleEdgeInsets.top = CGFloat(titleTopPadding)
       }
    }

    @IBInspectable var titleBottomPadding: Double = 0.0 {
       didSet {
           titleEdgeInsets.bottom = CGFloat(titleBottomPadding)
       }
    }
    
    
    //imageEdgeInsets：圖片的偏移量
    @IBInspectable var imageLeftPadding: Double = 0.0 {
        didSet {
            if !enableImageRightAligned {
                imageEdgeInsets.left = CGFloat(imageLeftPadding)
            }
        }
    }
    
    @IBInspectable var imageRightPadding: Double = 0.0 {
        didSet {
            imageEdgeInsets.right = CGFloat(imageRightPadding)
        }
    }
    
    @IBInspectable var imageTopPadding: Double = 0.0 {
        didSet {
            imageEdgeInsets.top = CGFloat(imageTopPadding)
        }
    }
    
    @IBInspectable var imageBottomPadding: Double = 0.0 {
        didSet {
            imageEdgeInsets.bottom = CGFloat(imageBottomPadding)
        }
    }

    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        if enableImageRightAligned,
            let imageView = imageView {
            
            print("image view width = \(imageView.bounds.size.width)")
            print("frame = \(self.frame.size.width)")
            print("image view width = \(imageView.frame.size.width)")
                
            print("image left padding = \(imageLeftPadding)")
            imageEdgeInsets.left = self.bounds.width - imageView.bounds.size.width - CGFloat(imageLeftPadding)
        }
        
        if enableGradientBackground {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.bounds
            gradientLayer.colors = [gradientColorBlack.cgColor, gradientColorWhite.cgColor]
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
    }
}
