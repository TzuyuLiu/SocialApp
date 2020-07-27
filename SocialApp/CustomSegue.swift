//
//  CustomSegue.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/4.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

class CustomSegue: UIStoryboardSegue {

    //自己定義展現的方式
    override func perform(){
       
        //firstVCView代表來源控視圖制器(目前的view controller)
        var firstVCView = self.source.view as! UIView
        
        //準備要呈現的view controller
        var secondVCView = self.destination.view as! UIView
        
        //取得畫面的寬與高
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        //指定second view controller的初始位置(在目前view的下方)
        secondVCView.frame = CGRect.init(x: 0.0, y: screenHeight, width: screenWidth, height: screenHeight)
        
        //取得app的 key window
        let window = UIApplication.shared.keyWindow
        
        //將second view controller加入window的sub view
        //這裏sub view的順序都以堆疊方式存放(above)，insertSubview(_:aboveSubview:)代表在指定的view上插入subview，在這裡代表secondVCView在firstVCView之上
        window?.insertSubview(secondVCView, aboveSubview: firstVCView)
        
        //產生轉換動畫
        UIView.animate(withDuration: 0.5, animations: {
            
            //將first view controller會從最上面消失，同時將secnod view controller移動到first view controller的位置
            firstVCView.frame = firstVCView.frame.offsetBy(dx: 0.0, dy: -screenHeight)
            secondVCView.frame = secondVCView.frame.offsetBy(dx: 0.0, dy: -screenHeight)
            
        }) { (Finished)-> Void in
            
            //最後呈現second view controller，才會有畫面
            self.source.present(self.destination as UIViewController, animated: false, completion: nil)
        }
    }
}
