//
//  extensionViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/12.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

extension UIViewController {
    
    func alert(title theTitleIs: String,message theMessageIs: String){
        //輸入不完整按下的話會送出UIAlertController
        let alertController = UIAlertController(title: theTitleIs, message: theMessageIs, preferredStyle: .alert)
        //ok按鈕，按下會取消 UIAlertAction
        let okayAction = UIAlertAction(title: "確定", style: .cancel, handler: nil)
        //在alertController下方加上ok按鈕
        alertController.addAction(okayAction)
        //呈現出alertController
        present(alertController,animated: true, completion: nil)
    }
    
    //將畫面跳轉到跳到whichController畫面
    func gotoSpectificViewController(whichController: String){
        //使用instantiateViewController使用實體化viewcontroller
        if let viewController = self.storyboard?.instantiateViewController(identifier: whichController){
            //並將他設定為root view controller
            UIApplication.shared.keyWindow?.rootViewController = viewController
            //完成後就會移除畫面
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension UIViewController:NVActivityIndicatorViewable{
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

