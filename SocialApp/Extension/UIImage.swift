//
//  UIImage.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/25.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

extension UIImage{
    //將url轉化成圖片的方法
    public static func loadImageFrom(url: URL, completion: @escaping (_ image: UIImage?) -> ()){
        DispatchQueue.global().async {
            //從網路擷取數據
            if let data = try? Data(contentsOf: url){
                DispatchQueue.main.async {
                    //數據用UIImage初始化圖片
                    completion(UIImage(data: data))
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    //將照片解析度下降，檔案縮小
    func scale(newWidth: CGFloat) -> UIImage{
        //確認設定的寬度
        if self.size.width == newWidth{
            return self
        }
        //計算縮放大小
        let scaleFactor = newWidth / self.size.width
        let newHeight = self.size.height * scaleFactor
        let newSize = CGSize(width: newWidth,height: newHeight)
        //將螢幕截圖保存到UIImage context中
        //參數1:創造出來的bitmap大小，參數2:透明/不透明，參數3:縮放,0代表不縮放
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x:0, y:0, width: newWidth, height: newHeight))
        //取得新的圖片
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        //關閉UIImage context
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
}
