//
//  CacheManager.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/3.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation

enum CacheConfiguration{
    static let maxObject = 100
    static let maxSize = 1024 * 1024 * 200
}

final class CacheManager{
    static let shared: CacheManager = CacheManager()
    
    //NSCache有兩個屬性作為管理cache大小，定義數量以及最大容量
    private static var cache: NSCache<NSString, AnyObject> = {
        let cache = NSCache<NSString, AnyObject>()
        //最多存放100個object
        cache.countLimit = CacheConfiguration.maxObject
        //加大預設cache到200M
        cache.totalCostLimit = CacheConfiguration.maxSize
        
        return cache
    }()
    
    private init() {}
    
    func cache(object: AnyObject,key: String){
        //透過CacheManager.cache.setObject來將object加到cache
        CacheManager.cache.setObject(object, forKey: key as NSString)
    }
    
    func getFromCache(key: String) -> AnyObject? {
        //使用CacheManager.cache.object來取得cache物件
        return CacheManager.cache.object(forKey: key as NSString)
    }
}
