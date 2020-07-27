//
//  AppDelegate.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/7.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import GoogleSignIn
import LineSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //在app啟動時設定一般UI元件的樣式與顏色
        customizeUIStyle()
        //在app啟動時初始化與設置firebase，程式碼會在app一啟動就連結firebse
        FirebaseApp.configure()
        //在app啟動時設置facebook登入
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        //在app啟動時初始化google sign in的用戶端id
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        //line的登入，chaneelID是指在line上的channel id
        LoginManager.shared.setup(channelID: "1654235817", universalLinkURL: nil)
        return true
    }
    
    //若有切換到facebook app，Facebook App切回這個app時，此方法application(_:open_options:)會被調用，所以實作方法來處理登入
    //app需要處理兩種型態的url
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]=[:]) -> Bool {
       
        var handled: Bool = false

        if url.absoluteString.contains("fb") {
            //由Facebook呼叫ApplicationDelegate的application方法處理facebook登入資訊
            handled = ApplicationDelegate.shared.application(app, open: url, options: options)
        } else if url.absoluteString.contains("google") {
        //google用GIDSignIn實例中的handleURL方法來登入，handleURL方法會處理最後驗證程序所接收的URL
            handled = GIDSignIn.sharedInstance().handle(url)
        } else if url.absoluteString.contains("line"){
            handled = LoginManager.shared.application(app, open: url, options: options)
        }
        return handled
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate {
    func customizeUIStyle() {
        
        // Customize Navigation bar items
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "Avenir", size: 16)!, NSAttributedString.Key.foregroundColor: UIColor.white], for: UIControl.State.normal)
    }
}

