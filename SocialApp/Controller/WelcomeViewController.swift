//
//  WelcomeViewController.swift
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

class WelcomeViewController: UIViewController {

    @IBOutlet weak var lineButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //指定google的委派
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        //設定line按鈕圖片，避免成為藍色
        //因為system類型下button的image默認以alwaysTemplate渲染成藍色，所以要設定
        let lineImage = UIImage(named: providerID.line.rawValue)?.withRenderingMode(.alwaysOriginal)
        lineButton.setImage(lineImage, for: .normal)
        let googleImage = UIImage(named: providerID.google.rawValue)?.withRenderingMode(.alwaysOriginal)
        googleButton.setImage(googleImage, for: .normal)
    }
    
    //viewdidload時有些viewcontroller的properities還沒準備好，所以跳轉viewcontroller不會有動作
    override func viewDidAppear(_ animated: Bool) {
        testAccessToken()
    }
    
    //facebook登入功能
    @IBAction func facebookLogin(sender: UIButton){
        //facebook的LoginManager提供登入與登出的方法
        let fbLoginManager = LoginManager()
        //因為需要email與使用者名稱，所以要求的使用者權限為public_profile與email
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            //從facebook的AcceeeToken取得使用者token
            guard let accessToken = AccessToken.current else {
                print("未登入")
                return
            }
            
            //使用firebase提供的FacebookAuthProvider.credential(withAccessToken:)將facebook的使用者token轉換成firebase的憑證
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            //使用憑證執行登入
            Auth.auth().signIn(with: credential) { (result, error) in
                guard error == nil else {
                    print("Login error: \(error!.localizedDescription)")
                    self.alert(title: "登入失敗", message: error!.localizedDescription)
                    return
                }
                //存入登入方式
                UserDefaults.standard.set(credential.provider, forKey: UserKey.provider.rawValue)
                //呈現MainView畫面
                self.gotoSpectificViewController(whichController: controllerID.mainView.rawValue)
            }
        }
    }
    
    //Line login方法
    @IBAction func lineLogin(sender: UIButton){
        LoginManager.shared.login(permissions: [.profile], in: self) {
            result in
            switch result {
            case .success(_):
                //存入登入方式
                UserDefaults.standard.set(providerID.line.rawValue, forKey: UserKey.provider.rawValue)
                //呈現MainView畫面
                self.gotoSpectificViewController(whichController: controllerID.mainView.rawValue)
            case .failure(let error):
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func googleLogin(sender: UIButton){
        //這裡的signIn是開始登入google的程序
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    @IBAction func unwindSegueWelcomeView(segue: UIStoryboardSegue){
        dismiss(animated: true, completion: nil)
    }
    
    func testAccessToken() {
        let provider = UserDefaults.standard.string(forKey: UserKey.provider.rawValue)
        //查看有沒有firebase database的access token，沒有的話再查看有沒有line的access token，line驗證access token是否有過期
        //Auth.auth().currentUser只能知道之前是否有user，並不能知道是否登出
        //line的verify accesstoken就算失效了還是會一值存在所以用provider判斷
        if provider != nil {
            switch provider {
            case providerID.password.rawValue,providerID.facebook.rawValue,providerID.google.rawValue:
                if Auth.auth().currentUser != nil {
                    gotoSpectificViewController(whichController: controllerID.mainView.rawValue)
                }
            case providerID.line.rawValue:
                API.Auth.verifyAccessToken { (result) in
                    switch result{
                    case .success(_):
                        self.gotoSpectificViewController(whichController: controllerID.mainView.rawValue)
                    case .failure(let error):
                        print(error)
                    }
                }
            default:
                break
            }
        }
    }
}

//要實作google sign in，必須採用兩個協定： GIDSignInDelegate與GIDSignInUIDelegate
extension WelcomeViewController:GIDSignInDelegate{
    //會在登入程序完成時被呼叫
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        //檢查是否有錯
        guard error == nil else {
            print("error: \(error.localizedDescription)")
            return
        }
        //沒錯誤就用 user.authentication取得Google id的token以及google access token
        guard let authentication = user.authentication else {
            print("沒有取得使用者的authentication")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        //將兩種token轉換成firebase驗證
        Auth.auth().signIn(with: credential) { (result, error) in
            guard error == nil else{
                print("Login error: \(error!.localizedDescription)")
                self.alert(title: "登入失敗", message: error!.localizedDescription)
                return
            }
            //存入登入方式
            UserDefaults.standard.set(credential.provider, forKey: UserKey.provider.rawValue)
            //呈現MainView畫面
            self.gotoSpectificViewController(whichController: controllerID.mainView.rawValue)
        }
    }
    
    //使用者與app斷線時會被呼叫
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
}
