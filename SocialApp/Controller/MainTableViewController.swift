//
//  MainViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/12.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase
import YPImagePicker
import Firebase
import LineSDK
import NVActivityIndicatorView

class MainTableViewController: UITableViewController {
    
    //算第幾頁
    fileprivate var pageCount = 1
    //存放下載的資料
    var photosData: [Photos] = []
    //是否從firebase下載post
    fileprivate var isLoadingPhoto = false
    let rest = RestManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.makeNavigationBarTransparent()
        self.navigationController?.adjustmentNavigationTitleFontAndColor()
        self.title = "SocialApp"
        //開始載入動畫
        self.startAnimating()
        let provider = UserDefaults.standard.string(forKey: UserKey.provider.rawValue)
        if provider == providerID.password.rawValue || provider == providerID.facebook.rawValue || provider == providerID.google.rawValue{
            //儲存完成後會移除載入動畫
            storeFirebaseData()
        } else if provider == providerID.line.rawValue {
            //儲存完成後會移除載入動畫
            storeLineUserData()
        }
        loadPhotos()
        tableView.backgroundView = UIImageView(image: UIImage(named: "background1"))
        tableView.backgroundView?.contentMode = .scaleAspectFill
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUserImageButton()
    }
    
    @IBAction func unwindSegueFromSelectedPhoto(segue: UIStoryboardSegue){
        let source = segue.source as? UserViewController
        if source?.userProfileChange == true {
            setUserImageButton()
        }
    }
    
    @objc private func gotoUserView(){
        if let controller = storyboard?.instantiateViewController(withIdentifier: controllerID.userView.rawValue){
            //使用navigationController中的pushViewController來維持navigationController
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    //設定右上角按鈕為使用者頭像
    private func setUserImageButton(){
        if let data = UserDefaults.standard.data(forKey: UserKey.userPhoto.rawValue) {
            let button = UIButton()
            button.imageView?.contentMode = .scaleAspectFill
            button.imageView?.layer.cornerRadius = 16
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(data: data), for: .normal)
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            button.addTarget(self, action: #selector(gotoUserView), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        } else {
            let button = UIButton()
            button.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
            button.addTarget(self, action: #selector(gotoUserView), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    }
    
    //MARK:- 下載與顯示photo
    @objc func loadPhotos(){
        isLoadingPhoto = true
        UnsplashService.shared.getPhoto(whichPage: pageCount) { (newPhotos) in
            if newPhotos.count > 0 {
                //加入photos到array最前面
                self.photosData.insert(contentsOf: newPhotos, at: 0)
            }
            self.isLoadingPhoto = false
            //更新tableview一定要在main thread做，這裡是在背景設定image，所以要用DispatchQueue切換到main thread
            DispatchQueue.main.async {
                self.displayPhotos(newPhotos: newPhotos)
                //檢查是否沒關掉loading動畫
                if self.isAnimating {
                    self.stopAnimating()
                }
            }
        }
        pageCount += 1
    }
    
    private func displayPhotos(newPhotos photos: [Photos]){
        guard photos.count > 0 else{
            print("沒有新的照片")
            return
        }
        var indexPaths:[IndexPath] = []
        //將photos插入進table view
        self.tableView.beginUpdates()
        for num in 0...(photos.count-1){
            //在特定的section與row產生indexpath
            let indexPath = IndexPath(row: num, section: 0)
            indexPaths.append(indexPath)
        }
        //使用insertRows插入indexpath，插入位置是indexpath宣告的位置，fade:淡出
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
    
    //下載.儲存並使用使用者名稱與大頭照
    private func storeFirebaseData(){
       //有跟firbase連結的供應商取得照片使用的方法(email-password.facebook.google)
       if let currentUser = Auth.auth().currentUser?.providerData[0]{
           //儲存userID
           let userID = getUserID()
           UserDefaults.standard.set(userID, forKey: UserKey.userID.rawValue)
           //登入後使用currentUser來取得使用者物件
           let userName = UserDefaults.standard.string(forKey: UserKey.userName.rawValue)
           //第一次登入時userDefaults會沒有儲存使用者
           if userName == nil {
               UserDefaults.standard.set(currentUser.displayName, forKey: UserKey.userName.rawValue)
               //如果有大頭照就使用，absoluteString：將url轉換成string
               if var photoURL = currentUser.photoURL?.absoluteString {
                   //將照片調大
                   switch currentUser.providerID {
                   case providerID.facebook.rawValue:
                       photoURL = photoURL + "?width=400&height=400&return_ssl_resources=1"
                   case providerID.google.rawValue:
                       photoURL = photoURL.replacingOccurrences(of: "s96-c", with: "s400-c")
                   default:
                       break
                   }
                   //儲存url
                   UserDefaults.standard.set(photoURL, forKey: UserKey.photoURL.rawValue)
                   //string轉換url
                   guard let url = URL(string: photoURL) else {
                       print("firebase string轉url轉換失敗")
                       return
                   }
                   //使用userPhoto當作key，儲存照片的data至userDefaults以及firebases
                   if let data = try? Data(contentsOf: url){
                       UserDefaults.standard.set(data, forKey: UserKey.userPhoto.rawValue)
                      
                       guard let image = UIImage(data: data) else {
                           print("轉換成image失敗")
                           return
                       }
                      
                       //查看firebase有沒有使用者資料，若沒有則上傳使用者名稱與照片
                       //使用userID取得firebase上的資料
                       let firebaseService = FirebaseService.init(userID: userID)
                       firebaseService.getUserInfo { (user) in
                           if user.userName == ""{
                               firebaseService.uploadUserProfile(userName: currentUser.displayName!, userImage: image) {
                                   //上傳完成後停止loading
                                   DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                       self.stopAnimating()
                                   }
                               }
                           }
                       }
                   }
               }
           }
           downUserInfo(userID: userID)
       }
    }
       
    private func storeLineUserData(){
       API.getProfile { (result) in
           switch result {
           case .success(let userProfile):
               //儲存userID
               let userID = userProfile.userID
               UserDefaults.standard.set(userID, forKey: UserKey.userID.rawValue)
               //使用者名稱
               let userName = UserDefaults.standard.string(forKey: UserKey.userName.rawValue)
               if userName == nil {
                   UserDefaults.standard.set(userProfile.displayName, forKey: UserKey.userName.rawValue)
                   //使用者的大頭照
                   if let userPhotoUrl = userProfile.pictureURL{
                       UserDefaults.standard.set(userPhotoUrl.absoluteString, forKey: UserKey.photoURL.rawValue)
                       if let data = try? Data(contentsOf: userPhotoUrl){
                          UserDefaults.standard.set(data, forKey: UserKey.userPhoto.rawValue)
                          guard let image = UIImage(data: data) else {
                              print("轉換image失敗")
                              return
                          }
                          //查看firebase有沒有使用者資料，若沒有責上傳使用者名稱與照片
                          let firebaseService = FirebaseService.init(userID: userID)
                          firebaseService.getUserInfo { (user) in
                              if user.userName == "" {
                                  firebaseService.uploadUserProfile(userName: userProfile.displayName, userImage: image) {
                                      //上傳完成後停止loading
                                      DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                          self.stopAnimating()
                                      }
                                  }
                              }
                          }
                          self.setUserImageButton()
                      }
                  }
               }
               self.downUserInfo(userID: userID)
           case .failure(let error):
               print("get line profile error: \(error)\n")
           }
       }
   }
    
    //MARK:- 取得使用者ID
    private func getUserID() -> String{
        let provider =  UserDefaults.standard.string(forKey: UserKey.provider.rawValue)
        var userID: String =  ""
        //代表是使用firebase方法
        if provider == providerID.facebook.rawValue || provider == providerID.google.rawValue || provider == providerID.password.rawValue {
            let user = Auth.auth().currentUser
            userID = user!.uid
        }
        return userID
    }
    
    //使用firebase下載的使用者資訊作為姓名為照片
    private func downUserInfo(userID: String){
        let firebaseService = FirebaseService.init(userID: userID)
        firebaseService.getUserInfo { (user) in
            //儲存名字
            let userNmae = user.userName
            UserDefaults.standard.set(userNmae, forKey: UserKey.userName.rawValue)
            //轉換string成url
            guard let imageURL = URL(string: user.userPhotoURL) else {
                print("downUserInfo中轉換imageURL失敗")
                return
            }
            if let data = try? Data(contentsOf: imageURL){
                //儲存照片
                UserDefaults.standard.set(data, forKey: UserKey.userPhoto.rawValue)
            }
        }
    }
}

//MARK:- UITableViewDataSource方法
extension MainTableViewController{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId.cell.rawValue, for: indexPath) as! PhotoCell
        let currentPhotos = photosData[indexPath.row]
        //使用cache加速
        cell.configure(url: currentPhotos.urls.regular, grapher: currentPhotos.user.name)
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosData.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //將每個cell調整到與photo一樣比例的尺寸
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = Double(tableView.frame.width) / Double(photosData[indexPath.row].width) * Double(photosData[indexPath.row].height)
        return CGFloat(cellHeight)
    }

    //往下滾動更新
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isLoadingPhoto, photosData.count - indexPath.row == 10 else {
            return
        }
        isLoadingPhoto = true
        //一次更新一個page
        UnsplashService.shared.getPhoto(whichPage: pageCount) { (newPhotos) in
            DispatchQueue.main.async {
                var indexPaths:[IndexPath] = []
                self.tableView.beginUpdates()
                for newPhoto in newPhotos {
                    self.photosData.append(newPhoto)
                    let indexPath = IndexPath(row: self.photosData.count-1, section: 0)
                    indexPaths.append(indexPath)
                }
                self.tableView.insertRows(at: indexPaths, with: .fade)
                self.tableView.endUpdates()
            }
        }
        isLoadingPhoto = false
        pageCount += 1
    }
}

//MARK:- prepare segue
extension MainTableViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell {
            if let selectedRow = tableView.indexPath(for: cell)?.row{
                if segue.identifier == segueID.mainToSelectedPhotoSegue.rawValue {
                    if let selectedPhotoVC = segue.destination as? SelectedPhotoViewController {
                        selectedPhotoVC.photoFile = photosData[selectedRow]
                    }
                }
            }
        }
    }
}
