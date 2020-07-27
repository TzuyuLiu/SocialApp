//
//  LoginViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/9.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var hidePasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.makeNavigationBarTransparent()
        self.navigationController?.adjustmentNavigationTitleFontAndColor()
    }
    
    @IBAction func login(sender:UIButton){
        //輸入驗證
        guard let emailaddress = emailTextField.text, !emailaddress.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
             alert(title: "登入訊息不完整", message: "帳號密碼請勿空白")
            return
        }
        
        //呼叫firebase API執行登入
        Auth.auth().signIn(withEmail: emailaddress, password: password) { (result, error) in
            //如果有error就進入登入失敗
            guard error == nil else{
               self.alert(title: "登入失敗", message: error!.localizedDescription)
               return
            }
            //檢查信箱是否驗證
            guard let result = result, result.user.isEmailVerified else {
                let alertController = UIAlertController(title: "登入失敗", message: "尚未驗證信箱，若需要重新寄驗證信，請按重寄驗證信", preferredStyle: .alert)
                let resendAction = UIAlertAction(title: "重新寄送驗證信", style: .default) { (action) in
                    Auth.auth().currentUser?.sendEmailVerification(completion: nil)
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                alertController.addAction(resendAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            //解除鍵盤
            self.view.endEditing(true)
            //加入provider
            UserDefaults.standard.set(Auth.auth().currentUser?.providerData[0].providerID, forKey: UserKey.provider.rawValue)
            //登入完就後會移除登入畫面，跳到程式主畫面中
            self.gotoSpectificViewController(whichController: "MainView")
        }
    } //login function
    
    //按下顯示密碼的按鈕後，密碼會顯示，並且圖片也轉成眼睛
    @IBAction func pressHidePasswordButton(_ sender: Any) {
        let image =  passwordTextField.isSecureTextEntry == true ? "eye" : "eye.slash"
        hidePasswordButton.setImage(UIImage(systemName: image), for: .normal)
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
    }
}
