//
//  FirebaseService.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/3.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseStorage
import LineSDK

final class FirebaseService{
    
    //MARK:- 屬性
    //設定一個static的shared來讓其他物件使用PostService
    static let shared: FirebaseService = FirebaseService()
    private init() {
    }
    
    //MARK:- Firebase Database 參照
    //預設使用位置
    //存取跟資料庫位置的database參照
    var BASE_DB_REF: DatabaseReference = Database.database().reference()
    //存取/posts位置的database參照
    var POST_DB_REF: DatabaseReference = Database.database().reference().child("posts")
    //存取like位置的參照
    var like_DB_REF: DatabaseReference = Database.database().reference().child("likePhotos")
    //MARK:- Firebase Storage 參照
    //存取資料庫位置的storage參照
    var USER_STORAGE_REF: StorageReference = Storage.storage().reference().child("userInfo")
    //存取/photos檔案夾的storage參照
    var PHOTO_STORAGE_REF: StorageReference = Storage.storage().reference().child("photos")
    
    //設定userID以及其他參數，不使用lazy var，因為只能設定一次
    init(userID: String) {
        BASE_DB_REF = Database.database().reference().child(userID)
        POST_DB_REF = Database.database().reference().child(userID).child("posts")
        like_DB_REF = Database.database().reference().child(userID).child("likePhotos")
        USER_STORAGE_REF = Storage.storage().reference().child(userID).child("userInfo")
        PHOTO_STORAGE_REF = Storage.storage().reference().child(userID).child("photos")
    }
    
    //MARK:- Firebase上傳與下載方法
    func uploadImage(image:UIImage, completionHandler:@escaping() -> Void){
        //產生一個貼文的unique ID並準備貼文database的reference
        let postDatabaseRef = POST_DB_REF.childByAutoId()
        //取得postDatabaseRef最後一段位置
        guard let imageKey = postDatabaseRef.key else{
            print("無法產生出postDataRef的key")
            return
        }
        let imageStorageRef = PHOTO_STORAGE_REF.child("\(imageKey).jpg")
        //調整圖片大小，調整至system width
        let scaledImage = image.scale(newWidth: 640.0)
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.9) else {
            print("無法縮小圖片")
            return
        }
        
        //建立檔案資料
        let metadata = StorageMetadata()
        //object data的資料型態
        metadata.contentType = "image/jpg"
        //準備上傳任務
        let uploadTask = imageStorageRef.putData(imageData, metadata: metadata)
        
        //觀察三種上傳狀態
        //上傳成功後要做什麼
        uploadTask.observe(.success) { (snapshot) in
            guard let displayName = UserDefaults.standard.string(forKey: UserKey.userName.rawValue) else {
                print("無法取得Userdefaults裡的displayName")
                return
            }
            //從reference取得url
            snapshot.reference.downloadURL { (url, error) in
                guard let url = url else {
                   print("無法取得reference中的downloadURL")
                   return
                }
                //詳細資訊為imageFileURL. timestamp. votes以及user四種
                let imageFileURL = url.absoluteString
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                //存放貼文資料的dictionary
                let post:[String: Any] = ["imageFileURL" : imageFileURL,
                                         "votes" : Int(0),
                                         "user" : displayName,
                                         "timestamp" : timestamp]
                //設定user object(postDatabaseRef)資料的詳細資訊到database
                postDatabaseRef.setValue(post)
            }
            //閉包，呼叫此可以傳遞一個函數，在貼文上傳後執行
            completionHandler()
            print("upload success")
        }
        
        //觀察上傳狀態
        uploadTask.observe(.progress) { (snapshot) in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Uploading \(imageKey).jpg... \(percentComplete)% complete")
        }
        
        //觀察失敗狀態
        uploadTask.observe(.failure) { (snapshot) in
            //缺少取消等待動畫
            //self.cancelLoadingView()
            if let error = snapshot.error{
                print("觀察出現failure")
                print(error.localizedDescription)
            }
        }
    }
    
    //上傳使用者姓名與大頭照
    func uploadUserProfile(userName:String,userImage: UIImage, completionHandler:@escaping() -> Void){
        let userDatabaseRef = BASE_DB_REF.child("userInfo")
        let userImageStorageRef = USER_STORAGE_REF.child("userPhoto.jpg")
        //轉換image成data
        guard let imageData = userImage.jpegData(compressionQuality: 1.0) else {
            print("轉換imageData失敗")
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        //準備上傳任務
        let uploadTask = userImageStorageRef.putData(imageData, metadata: metadata)
        
        uploadTask.observe(.success) { (snapshot) in
            //從reference取得url
            snapshot.reference.downloadURL { (url, error) in
                guard let url = url else {
                   print("無法取得reference中的downloadURL")
                   return
                }
                //詳細資訊為userPhotoURL與userName
                let userPhotoURL = url.absoluteString
                let userDetail:[String:Any] = ["userPhotoURL":userPhotoURL,
                                               "userName":userName]
                userDatabaseRef.setValue(userDetail)
            }
            //閉包，呼叫此可以傳遞一個函數，在貼文上傳後執行
            completionHandler()
            print("upload success")
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Uploading userphoto.. \(percentComplete)% complete")
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error{
                print("上傳失敗\n")
                print(error.localizedDescription)
            }
        }
    }
    
    //用來取得比時戳更晚的post，並且算post的方式為最晚到最早，limit：取得post數量
    func getRecentPosts(start timestamp: Int? = nil,limit: UInt,completionhandler: @escaping([Post]) -> Void) {
        var postQuery = POST_DB_REF.queryOrdered(byChild: Post.PostInfoKey.timestamp)
        print("POST_DB_REF:\(POST_DB_REF)")
        if let latestPostTimestamp = timestamp, latestPostTimestamp > 0 {
            //如果有指定時戳，會以比給定值來的新的時戳取得貼文
            //使用queryStarting(atValue:childKey)：會取得比atValue還晚的貼文
            //queryLimited(toLast)：用來限制取得的筆數，firebase以時間排序貼文，越晚的越後面，所以從最後面(toLast)開始算
            postQuery = postQuery.queryStarting(atValue: latestPostTimestamp + 1 , childKey:  Post.PostInfoKey.timestamp).queryLimited(toLast: limit)
        } else {
            //沒指定時戳，就取得最近的貼文
            postQuery = postQuery.queryLimited(toLast: limit)
        }
        //呼叫firebase api取得最新的資料記錄，使用observeSingleEvent來監聽data，.value：監聽符合任何改變的child node
        //snapshot包含所有從 /posts路徑所取得的posts
        //若沒有取得東西，snapshot則是nil(若時戳之後沒post)
        postQuery.observeSingleEvent(of: .value) { (snapshot) in
            var newPosts: [Post] = []
            //所有的post都是以一個dictionary array儲存在snapshot.children.allObjects
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                let postInfo = item.value as? [String:Any] ?? [:]
                
                if let post = Post(postID: item.key, postInfo: postInfo) {
                    newPosts.append(post)
                }
            }
            if newPosts.count > 0 {
                //以降幂排序(最新的為第一則貼文)
                newPosts.sort(by: { $0.timestamp > $1.timestamp})
            }
            //最後將排好的貼文array傳給completionandler使用
            completionhandler(newPosts)
        }
    }

    //用來取得比時戳更早的post，算post的方式為最晚到最早，limit：取得post數量
    func getOldPosts(start timestamp:Int,limit: UInt,completionhandler: @escaping([Post]) -> Void){
        let postOrderedQuery = POST_DB_REF.queryOrdered(byChild: Post.PostInfoKey.timestamp)
        //queryEnding：取得比atValue還早的post
        let postLimitedQuery = postOrderedQuery.queryEnding(atValue: timestamp - 1 , childKey: Post.PostInfoKey.timestamp).queryLimited(toLast: limit)
        
        postLimitedQuery.observeSingleEvent(of: .value) { (snapshot) in
            var newPosts: [Post] = []
            for item in snapshot.children.allObjects as! [DataSnapshot]{
                let postInfo = item.value as? [String:Any] ?? [:]
                
                if let post = Post(postID: item.key, postInfo: postInfo) {
                    newPosts.append(post)
                }
            }
            //以降幂排序(最新的為第一則貼文)
            newPosts.sort(by: { $0.timestamp > $1.timestamp})
            completionhandler(newPosts)
        }
    }
    
    func getlikePhotos(completionhandler: @escaping([LikePhoto]) -> Void){
        let likeQuery = like_DB_REF.queryOrderedByKey()
        likeQuery.observeSingleEvent(of: .value) { (snapshot) in
            var likePhotos:[LikePhoto] = []
            for item in snapshot.children.allObjects as! [DataSnapshot] {
                let tempData = item.value as? [String:Any] ?? [:]
                if let photo = LikePhoto(photoInfo: tempData){
                    likePhotos.append(photo)
                }
            }
            completionhandler(likePhotos)
        }
    }
    
    func getUserInfo(completionhandler: @escaping(UserInfo) -> Void){
        let userInfoQuery = BASE_DB_REF.child("userInfo")
        userInfoQuery.observeSingleEvent(of: .value) { (snapshot) in
            var user:UserInfo = UserInfo()
            
            for item in snapshot.children.allObjects as! [DataSnapshot]{
                if item.key == UserInfo.UserInfoKey.userName {
                    user.userName = item.value as! String
                }
                switch item.key {
                case UserInfo.UserInfoKey.userName:
                    user.userName = item.value as! String
                case UserInfo.UserInfoKey.userPhotoURL:
                    user.userPhotoURL = item.value as! String
                default: break
                }
            }
            completionhandler(user)
        }
    }
    
    //MARK:- Firebase like照片方法
    func isPhotoLiked(photoURL: String,completionHandler: @escaping(Bool) -> Void){
        let likeDatabaseRef = like_DB_REF.queryOrdered(byChild: "photoURL").queryEqual(toValue: photoURL)
        likeDatabaseRef.observeSingleEvent(of: .value, with: { (snapshot) in
            var isLiked:Bool
            if snapshot.childrenCount > 0 {
               isLiked = true
            } else {
               isLiked = false
            }
            completionHandler(isLiked)
        })
    }
    
    func likePhoto(photoURL: String,grapher: String,width: Int, height: Int,completionHandler:@escaping() -> Void){
        //產生一個貼文的unique ID並準備貼文database的reference
        let likeDatabaseRef = like_DB_REF.childByAutoId()
        print("likeDatabaseRef: \(likeDatabaseRef)")
        let likePhoto:[String:Any] = ["photoURL":photoURL,
                                      "name":grapher,
                                      "width":width,
                                      "height":height]
        likeDatabaseRef.setValue(likePhoto) { (error, ref) in
            guard error == nil else {
                print("error: \(error.debugDescription)")
                return
            }
            self.like_DB_REF.observe(.value) { (snapshot) in
                completionHandler()
            }
        }
    }
    
    func disLikePhoto(photoURL: String,completionHandler:@escaping() -> Void){
        var key: String = ""
        let disLikeDatabaseRef = like_DB_REF
        disLikeDatabaseRef.queryOrdered(byChild: "photoURL").queryEqual(toValue: photoURL).observeSingleEvent(of: .value) { (snapshot) in
            //找到與photoURL一樣位置的node
            if let snapshots = snapshot.children.allObjects as? [DataSnapshot]{
                for photoInfo in snapshots {
                    key = photoInfo.key
                }
            }
            //找到之後刪除node
            disLikeDatabaseRef.child(key).removeValue()
            disLikeDatabaseRef.observe(.value) { (snapshot) in
                completionHandler()
            }
        }
    }
    
}
