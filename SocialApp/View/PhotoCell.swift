//
//  PhotoCell.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/5.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

class PhotoCell: UITableViewCell {
    
    //讓cell對應到正確的photo image
    private var currentPhotoUrl: String?
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    //將photo放到cell上
    func configure(url: String,grapher:String){
    //設定目前post
        currentPhotoUrl = url
        //設定cell樣式
        selectionStyle = .none
        //設定名稱與按讚數
        nameLabel.text = grapher
        //重設圖片視圖的圖片
        photoImageView.image = nil
        //下載貼文圖片
        //檢查cache是否有圖片，有就直接拿來用
        if let image = CacheManager.shared.getFromCache(key: url) as? UIImage{
            photoImageView.image = image
        } else {
            //cache中沒有就上unsplash下載
            if let onlineURL = URL(string: url) {
                let downloadTask = URLSession.shared.dataTask(with: onlineURL) { (data, response, error) in
                    guard let imageData = data else {
                        print("無法取得imageData")
                        return
                    }
                    OperationQueue.main.addOperation {
                        guard let image = UIImage(data: imageData) else {
                            print("class PhotoCell中image轉換有問題\n")
                            return
                        }
                        //檢查當下post的url是否就是目前post的url，避免被其他圖片覆蓋著
                        if self.currentPhotoUrl == url {
                            self.photoImageView.image = image
                        }
                        //加入下載圖片到cache，key就用url
                        CacheManager.shared.cache(object: image, key: url)
                    }
                }
                //啟動下載
                downloadTask.resume()
            }
        }
    }
}
