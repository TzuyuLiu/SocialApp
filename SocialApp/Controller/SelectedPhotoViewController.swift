//
//  SelectedPhotoViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/4.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class SelectedPhotoViewController: UIViewController {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var downloadButton: Button!
    @IBOutlet weak var likeButton: Button!
    var photoFile: Photos = Photos()
    var postFile: Post = Post()
    var likePhotoFile: LikePhoto = LikePhoto()
    var hideButton = false
    fileprivate var isInlikePhotoViewController = false
    //判斷接收到的資料是哪種在輸入
    lazy var photoPath = postFile.timestamp > 0 ? postFile.imageFileURL : photoFile.width > 0 ? photoFile.urls.regular : likePhotoFile.photoURL
    lazy var name = postFile.timestamp > 0 ? postFile.user : photoFile.width > 0 ? photoFile.user.name : likePhotoFile.name
    lazy var photoWidth = postFile.timestamp > 0 ? Int(view.frame.width) : photoFile.width > 0 ? photoFile.width : likePhotoFile.width
    lazy var photoHeight = postFile.timestamp > 0 ? Int(view.frame.width) : photoFile.height > 0 ? photoFile.height : likePhotoFile.height
    //使用userID取得firebase上的資料
    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.black
        self.navigationController?.makeNavigationBarTransparent()
        self.navigationController?.adjustmentNavigationTitleFontAndColor()
        //點擊一下會觸發hideNavigationButton()
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideNavigationButton))
        //增加點及手勢
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        isInlikePhotoViewController = photoPath == likePhotoFile.photoURL ? true : false
        loadPhoto(url: photoPath, grapherName: name)
    }
    
    //載入photo到cell，並載入愛心
    func loadPhoto(url: String,grapherName: String){
        //設定名稱到navigation controller title
        self.title = grapherName
        //檢查cache是否有圖片
        if let image = CacheManager.shared.getFromCache(key: url) as? UIImage{
            photoImageView.image = image
        } else {
            if let onlineURL = URL(string: url) {
                let downloadTask = URLSession.shared.dataTask(with: onlineURL) { (data, response, error) in
                    guard let imageData = data else {
                        print("無法取得image")
                        self.alert(title: "取得圖片失敗", message: "取得圖片遇到問題，請稍後再試")
                        return
                    }
                    OperationQueue.main.addOperation {
                        guard let image = UIImage(data: imageData) else {
                            print("image轉換有問題")
                            self.alert(title: "轉換圖片失敗", message: "轉換圖片遇到問題，請稍後再試")
                            return
                        }
                        CacheManager.shared.cache(object: image, key: url)
                    }
                }
                downloadTask.resume()
            }
        }
        firebaseService.isPhotoLiked(photoURL: url) { (isClickLiked) in
            if isClickLiked {
                self.likeButton.imageView?.tintColor = UIColor.red
            } else {
                self.likeButton.imageView?.tintColor = UIColor.systemGray4
            }
        }
    }
    
    //MARK:- like 與 download photo
    @IBAction func likeButtonPress(_ sender: UIButton) {
        firebaseService.isPhotoLiked(photoURL: photoPath, completionHandler: { (isClickLiked) in
            //如果還沒喜歡過就按喜歡
            if (!isClickLiked){
                //將喜歡的圖片增加到Firebase database
                self.firebaseService.likePhoto(photoURL: self.photoPath, grapher: self.name, width: self.photoWidth, height: self.photoHeight) {
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLikePhoto"), object: nil)
                }
            } else {
                //如果不是在likePhotoViewControlle就更新，如果是在likePhotoViewControlle就延遲到退出在更新
                if self.isInlikePhotoViewController == false {
                    self.firebaseService.disLikePhoto(photoURL: self.photoPath) {
                        NotificationCenter.default.post(name: NSNotification.Name("refreshLikePhoto"), object: nil)
                    }
                } else {
                    //退出更新時畫面會保持在此畫面不動
                    self.dismiss(animated: true, completion: nil)
                    self.firebaseService.disLikePhoto(photoURL: self.photoPath) {
                        NotificationCenter.default.post(name: NSNotification.Name("refreshLikePhoto"), object: nil)
                    }
                }
            }
            self.likeButton.imageView?.tintColor = isClickLiked == true ? UIColor.systemGray4 : UIColor.red
        })
    }
    
    @IBAction func downloadButtonPress(_ sender: UIButton) {
        let  activityData = ActivityData()
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData)
        if let image = CacheManager.shared.getFromCache(key: photoPath) as? UIImage{
            //將圖片儲存到photo album
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 0.5) {
                NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
            }
        } else {
            if let onlineURL = URL(string: photoPath) {
                let downloadTask = URLSession.shared.dataTask(with: onlineURL) { (data, response, error) in
                    guard let imageData = data else {
                        print("無法取得image")
                        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        return
                    }
                    OperationQueue.main.addOperation {
                        guard let image = UIImage(data: imageData) else {
                            print("image轉換有問題")
                            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                            return
                        }
                        CacheManager.shared.cache(object: image, key: self.photoPath)
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 0.5) {
                            NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        }
                    }
                }
                downloadTask.resume()
            }
        }
    }
}

//MARK:- 手勢會執行的function
extension SelectedPhotoViewController {
    @objc func hideNavigationButton(){
        //將隱藏navigationcontroller選項反轉
        hideButton = !(hideButton)
        //若只想隱藏navigationBar上的元件是使用isHidden，若用setNavigationBarHidden則會把整個navigationBar隱藏起來
        navigationController?.navigationBar.isHidden = hideButton
        downloadButton.isHidden = hideButton
        likeButton.isHidden = hideButton
    }
}
