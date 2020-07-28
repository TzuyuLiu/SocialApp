//
//  UserViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/5.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import YPImagePicker
import Firebase
import LineSDK

class UserViewController: UIViewController {
    
    //使用userID取得firebase上的資料
    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    let userPhotosTableViewController:UserPhotosTableViewController = UserPhotosTableViewController()
    var userProfileChange = false
    fileprivate var view1isHidden = true
    //放使用者資訊的container
    @IBOutlet weak var userProfileContainerView: UIView!
    //放兩個tableview的兩個container
    @IBOutlet var showPhotoContainViews: [UIView]!
    @IBOutlet weak var noPhotoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //對navigationcontroller透明化
        navigationController?.makeNavigationBarTransparent()
        //YPimagePicker Title color
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white ]
        let coloredImage = UIImage(ciImage: .black)
        UINavigationBar.appearance().setBackgroundImage(coloredImage, for: UIBarMetrics.default)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //會先顯示較快出現的tableview，為了確保userPhotos一開始顯示，所以要讓userLikes隱藏
        if view1isHidden {
            //隱藏userLikes tableview
            showPhotoContainViews[1].isHidden = true
        }
        noPhotoImageView.isHidden = true
        //因為沒有按下segment control，因此要先判斷userPhoto是否有照片
        showNoPhotoImage(selectedSegmentIndex: 0)
    }
    
    //MARK:- Segment Control控制
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        //將下方兩個container view都隱藏
        showPhotoContainViews.forEach { $0.isHidden = true }
        //顯示segment control選擇到的container view
        showPhotoContainViews[sender.selectedSegmentIndex].isHidden = false
        //每次切換時先將圖片隱藏起來
        noPhotoImageView.isHidden = true
        showNoPhotoImage(selectedSegmentIndex: sender.selectedSegmentIndex)
        if sender.selectedSegmentIndex == 1 {
            view1isHidden = false
        } else {
            view1isHidden = true
        }
    }
    
    //MARK:- Segue
    @IBAction func unwindSegueFromSelectedPhoto(segue: UIStoryboardSegue){
        let source = segue.source as? ProfileViewController
        if source?.userNameChange == true {
            sendUpgradData(userChange: UserKey.userName.rawValue)
        } else if source?.userPhotoChange == true {
            sendUpgradData(userChange: UserKey.userPhoto.rawValue)
            userProfileChange = true
        }
    }
    
    //MARK:- 與container溝通哪裡需要改變
    func sendUpgradData(userChange: String){
        let containerController = children.first as! UserProfileViewController
        containerController.chageData(whereNeedChange: userChange)
    }
    
    //MARK:- 相機拍照與上傳照片
    @IBAction func openCamera(_ sender: Any){
        var config = YPImagePickerConfiguration()
        // Set the default configuration for all pickers
        config.colors.safeAreaBackgroundColor = .black
        config.colors.libraryScreenBackgroundColor = .black
        config.colors.photoVideoScreenBackgroundColor = .black
        config.colors.bottomMenuItemBackgroundColor = .black
        config.colors.bottomMenuItemSelectedTextColor = .white
        config.colors.bottomMenuItemUnselectedTextColor = .lightGray
        config.colors.tintColor = .blue
        
        let imagePicker = YPImagePicker(configuration: config)

        //single photo
        imagePicker.didFinishPicking { [unowned imagePicker] items, _ in
            //取得選擇的東西，若是取得單張照片則往下執行
            //這邊的photo型態還不是image
            guard let photo = items.singlePhoto else {
                print("非單張照片")
                self.dismiss(animated: true, completion: nil)
                return
            }
            //更新圖片至雲端，使用.image轉換型態
            self.firebaseService.uploadImage(image: photo.image) {
                self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: NSNotification.Name("reloadUserPhotoTable"), object: nil)
                }
            }
        }
        //顯示imagePicker介面
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:- 無相片時顯示的圖片
    //selectedSegmentIndex：segment control目前是選擇哪個tableview
    private func getPhotoCount(selectedSegmentIndex index: Int,completionhandler: @escaping(Int) -> Void){
        //表示使用userPhotoTableView
        var photoCount = -1
        if index == 0 {
            //查看數量
            firebaseService.getRecentPosts(limit: 10) { (newPosts) in
                photoCount = newPosts.count
                completionhandler(photoCount)
            }
        }
        //表示使用userLikeTableView
        else {
            firebaseService.getlikePhotos { (likephotos) in
                photoCount = likephotos.count
                completionhandler(photoCount)
            }
        }
    }
    
    func showNoPhotoImage(selectedSegmentIndex index: Int) {
        //如果沒有photo則顯示沒有圖片的圖示
        _ = getPhotoCount(selectedSegmentIndex: index) { (photoCount) in
            if photoCount == 0 {
               self.noPhotoImageView.isHidden = false
               switch index {
               case 0:
                   let image = UIImage(named: "nophoto")?.withTintColor(.gray)
                   self.noPhotoImageView.image = image
               case 1:
                   let image = UIImage(named: "nolikephoto")?.withTintColor(.gray)
                   self.noPhotoImageView.image = image
               default:
                   break
              }
           }
        }
    }
}
