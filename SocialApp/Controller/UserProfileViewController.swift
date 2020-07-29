//
//  UserProfileViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/15.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase
import LineSDK

class UserProfileViewController: UIViewController {

    @IBOutlet weak var userPhotoImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    //使用userID取得firebase上的資料
    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.init(displayP3Red: 41.0, green: 36.0, blue: 33.0, alpha: 0)
        firebaseService.getUserInfo { (user) in
            self.userNameLabel.text = user.userName
        }
        userNameLabel.textColor = UIColor.white
        if let data = UserDefaults.standard.data(forKey: UserKey.userPhoto.rawValue){
            userPhotoImageView.image = UIImage(data: data)
        }
    }
    
    func chageData(whereNeedChange: String){
        if whereNeedChange == UserKey.userName.rawValue {
            userNameLabel.text = UserDefaults.standard.string(forKey: UserKey.userName.rawValue)
        }
        if whereNeedChange == UserKey.userPhoto.rawValue {
            if let data = UserDefaults.standard.data(forKey: UserKey.userPhoto.rawValue){
                userPhotoImageView.image = UIImage(data: data)
            } else {
                userPhotoImageView.image = UIImage(systemName: UserKey.blankprofile.rawValue)
            }
        }
    }
}
 
