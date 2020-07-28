//
//  UnsplashService.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/8.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation

final class UnsplashService{
    //MARK:- 屬性
    fileprivate let rest = RestManager()
    //設定一個static的shared來讓其他物件使用PostService
    static let shared: UnsplashService = UnsplashService()
    //避免其他物件建立這個類別的實例
    private init() {}
    
    //一次取得一個page的資料
    func getPhoto(whichPage: Int,completionhandler: @escaping([Photos]) -> Void){
        guard let url = URL(string: "https://api.unsplash.com/photos/?") else {
            print("沒有取得url")
            return
        }
        //為url加上query
        rest.urlQueryParameters.add(value: UnsplashKey.privateKey, forKey: UnsplashKey.client_id)
        rest.urlQueryParameters.add(value: "30", forKey: UnsplashKey.per_page)
        rest.urlQueryParameters.add(value: photosOrder.popular, forKey: UnsplashKey.order_by)
        rest.urlQueryParameters.add(value: String(whichPage) , forKey: UnsplashKey.page)
        rest.makeRequest(toURL: url, withHttpMethod: .get) { (result) in
            if let data = result.data{
                let decoder = JSONDecoder()
                guard let popularPhotos = try? decoder.decode([Photos].self, from: data) else {
                    print("沒取得Photos資料")
                    return
                }
                
                //取得第一個data與存在cache裡的key相比看是否已經載入過
                completionhandler(popularPhotos)
            }
        }
    }
}