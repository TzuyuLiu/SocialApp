//
//  UnsplashPhoto.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/5.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation
//MARK:- 屬性
struct Photos:Codable, CustomStringConvertible{
    var id: String
    var created_at: String
    var urls: Link
    var user: Info
    var height: Int
    var width: Int
    //用"""來表示隔行的string
    var description: String{
        let desc = """
        --------------------------------------------------
        id = \(id)
        created_at = \(created_at)
        urls = \(urls.regular)
        user = \(user.name)
        height = \(height)
        width = \(width)
        --------------------------------------------------
        """
        return desc
    }
    
    init() {
        self.id = ""
        self.created_at = ""
        self.height = 0
        self.width = 0
        self.urls = Link()
        self.user = Info()
    }
}

struct Info: Codable {
    var name: String
    init() {
        self.name = ""
    }
}

struct Link: Codable{
    var regular: String
    init() {
        self.regular = ""
    }
}

//MARK:- Unsplash Keys
enum UnsplashKey{
    
    static let privateKey = "輸入unsplash private key"
    static let client_id = "client_id"
    static let per_page = "per_page"
    static let order_by = "order_by"
    static let page = "page"
}

enum photosOrder{
    static let latest = "latest"
    static let oldest = "oldest"
    static let popular = "popular"
}
   
enum EndPoints{
   static let base = "https://unsplash.com"
}
