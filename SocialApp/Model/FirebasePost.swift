//
//  FirebasePost.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/3.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation

struct Post{
    //MARK:- 屬性
    var postID: String
    var imageFileURL: String
    var user: String
    var timestamp: Int
    
    //MARK:- Firebase Keys
    enum PostInfoKey{
        static let imageFileURL = "imageFileURL"
        static let user = "user"
        static let timestamp = "timestamp"
    }
    
    //MARK:- 初始化
    init(){
        self.postID = ""
        self.imageFileURL = ""
        self.user = ""
        self.timestamp = 0
    }
    
    init(postID: String,imageFileURL: String, user: String, timestamp: Int = Int(Date().timeIntervalSince1970 * 1000)){
        self.postID = postID
        self.imageFileURL = imageFileURL
        self.user = user
        self.timestamp = timestamp
    }
    
    init?(postID: String, postInfo: [String: Any]){
        //Any要轉換成其他型態
        guard let imageFileURL = postInfo[PostInfoKey.imageFileURL] as? String,
              let user = postInfo[PostInfoKey.user] as? String,
              let timestamp = postInfo[PostInfoKey.timestamp] as? Int else {
                print("沒有取得post資訊")
                return nil
        }
        self = Post(postID: postID, imageFileURL: imageFileURL, user: user, timestamp: timestamp)
    }
}

struct LikePhoto {
    //MARK:- 屬性
    var photoURL: String
    var name: String
    var height: Int
    var width: Int
    
    //MARK:- Firebase Keys
    enum PhotoInfoKey{
        static let photoURL = "photoURL"
        static let name = "name"
        static let height = "height"
        static let width = "width"
    }
    
    init() {
        self.photoURL = ""
        self.name = ""
        self.height = 0
        self.width = 0
    }
    
    init(photoURL: String,name: String,height: Int,width: Int) {
        self.photoURL = photoURL
        self.name  = name
        self.height = height
        self.width = width
    }
    
    init?(photoInfo:[String:Any]) {
        guard let photoURL = photoInfo[PhotoInfoKey.photoURL] as? String,
              let name = photoInfo[PhotoInfoKey.name] as? String,
              let height = photoInfo[PhotoInfoKey.height] as? Int,
              let width = photoInfo[PhotoInfoKey.width] as? Int else {
                return nil
        }
        self = LikePhoto(photoURL: photoURL, name: name, height: height, width: width)
    }
}

struct UserInfo{
    //MARK:-屬性
    var userName: String
    var userPhotoURL: String
    
    //MARK:- Firebase Key
    enum UserInfoKey{
        static let userName = "userName"
        static let userPhotoURL = "userPhotoURL"
    }
    init() {
        self.userName = ""
        self.userPhotoURL = ""
    }
    init(userName: String,userPhotoURL: String) {
        self.userName = userName
        self.userPhotoURL = userPhotoURL
    }
    init?(userInfo:[String:Any]){
        guard let userName = userInfo[UserInfoKey.userName] as? String,
              let userPhotoURL = userInfo[UserInfoKey.userPhotoURL] as? String else {
                  return nil
        }
        self = UserInfo(userName: userName,userPhotoURL: userPhotoURL)
    }
}
