//
//  UINavigationController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/9.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

extension UINavigationController{
    
    func makeNavigationBarTransparent(){
        //將背景設定為看不到的UIImage
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //消除分隔線
        self.navigationBar.shadowImage = UIImage()
        //navigationBar設定為半透明
        self.navigationBar.isTranslucent = true
    }
    
    func adjustmentNavigationTitleFontAndColor(){
        //返回鍵改成白色
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Rubik-Medium", size: 20)!,NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
}
