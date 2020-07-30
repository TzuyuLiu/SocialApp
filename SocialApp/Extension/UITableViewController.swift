//
//  UITableViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/7/30.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

//載入動畫設定
extension UITableViewController:NVActivityIndicatorViewable{
    func startAnimate() {
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        let size = CGSize(width: width, height: height)
        self.startAnimating(size, message: "Loading", type: .ballClipRotate)
    }
    func stopAnimate(){
        self.stopAnimating()
    }
}
