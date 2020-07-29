//
//  ProfileViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/12.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import GoogleSignIn
import LineSDK


class ProfileViewController: UIViewController {

    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var resetPasswordButton: Button!
    var userNameChange = false
    var userPhotoChange = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.makeNavigationBarTransparent()
        self.navigationController?.adjustmentNavigationTitleFontAndColor()
        resetPasswordButton.isHidden = true
        self.title = "設定"
        nameLabel.textColor = UIColor.white
        //取得使用者名稱與照片
        firebaseService.getUserInfo { (user) in
            self.nameLabel.text = user.userName
        }
        if let data = UserDefaults.standard.data(forKey: UserKey.userPhoto.rawValue){
            userImageView.image = UIImage(data: data)
        }
        configResetPasswordButton()
    }
    
    @IBAction func logout(sender:UIButton){
        //firebase的log out方法
        let provider = UserDefaults.standard.string(forKey: UserKey.provider.rawValue)
        if provider == providerID.password.rawValue || provider == providerID.google.rawValue || provider == providerID.facebook.rawValue {
            do{
                //各家公司的log out
                if let providerData = Auth.auth().currentUser?.providerData {
                    let userInfo = providerData[0]
                    //provierID是提供的公司
                    switch userInfo.providerID {
                    case providerID.facebook.rawValue:
                        let manager = LoginManager()
                        manager.logOut()
                    case providerID.google.rawValue:
                        GIDSignIn.sharedInstance().signOut()
                    default:
                        break
                    }
                }
                //signout有throw，所以要try
                //加上try後就要用do-catch
                try Auth.auth().signOut()
            } catch{
                alert(title: "登出錯誤", message: error.localizedDescription)
                return
            }
        } else if provider == providerID.line.rawValue{
            //line的log out方法
            LoginManager.shared.logout { (lineLogoutResult) in
                switch lineLogoutResult{
                case .success:
                    print("log out from line")
                case .failure(let error):
                    print("line log out error: \(error.localizedDescription)")
                    return
                }
            }
        }
        //將所有儲存在UserDefault的資訊抹除
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        //呈現歡迎畫面
        gotoSpectificViewController(whichController: controllerID.welcomeView.rawValue)
    }
    
    //重新設定照片
    @IBAction func resetUserPhoto(_ sender: Any) {
        //設置一個從底下出來的提示框
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let choicePhotoAction = UIAlertAction(title: "選擇照片", style: .default) { (_) in
            self.pickAndSavePhoto()
            self.userPhotoChange = true
        }
        alertController.addAction(choicePhotoAction)
        //.destructive字型會顯示紅色
        let removePhotoAction = UIAlertAction(title: "刪除", style: .destructive) { (_) in
            let personImage = UIImage(named: UserKey.blankprofile.rawValue)
            self.userImageView.image = personImage
            if let imageData = personImage?.pngData(){
                UserDefaults.standard.set(imageData, forKey: UserKey.userPhoto.rawValue)
            }
            guard let userName = UserDefaults.standard.string(forKey: UserKey.userName.rawValue) else {
                print("取得使用者名字失敗")
                return
            }
            //上傳使用者照片，使用blankprofile作為上傳的照片
            self.firebaseService.uploadUserProfile(userName: userName, userImage: personImage!) {
                print("更改使用者照片")
            }
            self.userPhotoChange = true
        }
        alertController.addAction(removePhotoAction)
        //顯示提示框
        self.present(alertController, animated: true, completion: nil)
    }
    
    //重新設定姓名
    @IBAction func resetUserName(_ sender: Any) {
        //建立提示框
        let alertController = UIAlertController(title: "更改名字", message: nil, preferredStyle: .alert)
        //增加輸入框
        alertController.addTextField { (textField) in
            textField.placeholder = "新名稱"
            textField.textAlignment = .center
        }
        //取消按鈕
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        //確定按鈕
        let okAction = UIAlertAction(title: "確定", style: .default) { (alertAction) in
            let userNameTextField = (alertController.textFields?.first)! as UITextField
            guard let userName = userNameTextField.text,userName != "" else {
                print("userName輸入錯誤")
                return
            }
            UserDefaults.standard.set(userName, forKey: UserKey.userName.rawValue)
            //上傳更改姓名，使用者圖片則是使用userDefaults中的圖片
            guard let imageData = UserDefaults.standard.data(forKey: UserKey.userPhoto.rawValue) else {
                print("從UserDefaults取得照片失敗")
                return
            }
            guard let userPhoto = UIImage(data: imageData) else {
                print("轉換大頭照失敗")
                return
            }
            self.firebaseService.uploadUserProfile(userName: userName, userImage: userPhoto) {
                print("更改使用者姓名")
            }
            self.nameLabel.text = userName
            self.userNameChange = true
        }
        alertController.addAction(okAction)
        //顯示提示框
        self.present(alertController, animated: true, completion: nil)
    }
    
    //是否要顯示ResetButton
    func configResetPasswordButton(){
        //分辨登入方法，若是使用email-password，則顯示reset password按鈕
        let provider = UserDefaults.standard.string(forKey: UserKey.provider.rawValue)
        if provider  == providerID.password.rawValue {
            resetPasswordButton.isHidden = false
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func pickAndSavePhoto(){
        let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
    }
    //實作ImagePickerDelegate中完成選擇照片後的方法
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //取得照片
        let image = info[.originalImage] as! UIImage
        userImageView.image = image
        //上傳使用者照片
        guard let userName = UserDefaults.standard.string(forKey: UserKey.userName.rawValue) else {
            print("取得使用者名字失敗")
            return
        }
        self.firebaseService.uploadUserProfile(userName: userName, userImage: image) {
            print("更改使用者姓名")
        }
        //用pngData將image轉換成data
        if let imageData = image.pngData(){
            UserDefaults.standard.set(imageData, forKey: UserKey.userPhoto.rawValue)
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
}

