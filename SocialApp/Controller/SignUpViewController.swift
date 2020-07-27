//
//  SignUpViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/11.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

//使用firebase驗證
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var reEnterPasswordTextField: UITextField!
    @IBOutlet weak var passwordButton: UIButton!
    @IBOutlet weak var reEnterPasswordButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.makeNavigationBarTransparent()
        self.navigationController?.adjustmentNavigationTitleFontAndColor()
    }
    
    //email-password方法的註冊流程
    @IBAction func registerAccount(sender: UIButton){
        //先驗證，檢查欄位是否有沒填
        guard var name = nameTextField.text,!name.isEmpty, var emailAddress = emailTextField.text, !emailAddress.isEmpty , var password = passwordTextField.text, !password.isEmpty, var reEnterPassword = reEnterPasswordTextField.text, !reEnterPassword.isEmpty else {
            alert(title: "註冊訊息不完整", message: "資訊請勿空白")
            //guard let ... else 可以用 return 跳出
            return
        }
        //如果字首字尾有空白，則去除前後空白
        name = name.trimmingCharacters(in: .whitespaces)
        emailAddress = emailAddress.trimmingCharacters(in: .whitespaces)
        password = password.trimmingCharacters(in: .whitespaces)
        reEnterPassword = reEnterPassword.trimmingCharacters(in: .whitespaces)
        //檢查中間是否有空格
        guard emailAddress.components(separatedBy: " ").count <= 1 else {
            alert(title: "信箱格式錯誤", message: "信箱不可有空格")
            return
        }
        guard password.components(separatedBy: " ").count <= 1 || reEnterPassword.components(separatedBy: " ").count <= 1 else {
            alert(title: "密碼格式錯誤", message: "密碼不可有空格")
            return
        }
        //檢查密碼輸入是否一致
        guard password == reEnterPassword else {
            alert(title: "密碼輸入錯誤", message: "密碼輸入不一致")
            return
        }
        //在Firebase註冊使用者帳號，createUser不會儲存姓名
        Auth.auth().createUser(withEmail: emailAddress, password: password) { (user, error) in
            guard error == nil else{
                self.alert(title: "註冊錯誤", message: error!.localizedDescription)
                return
            }
            //儲存使用者名稱
            //先使用createProfileChangeRequest來建立一個更變個人資料的物件
            //之後將使用者名稱存入firebase中的display
            //最後用commitChanges(completion:)提出改變並更新到firebase
            if let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest(){
                changeRequest.displayName = name
                changeRequest.commitChanges(completion: { (error) in
                    if let error = error {
                        print("Failed to change the display name:\(error.localizedDescription)")
                    }
                })
            }
            //移除鍵盤
            self.view.endEditing(true)
            
            //傳送確認email信件，有可能會回傳error
            Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                print("傳送驗證信件失敗")
            })
            
            let alertController = UIAlertController(title: "信箱驗證信件已送出", message: "已傳送驗證信件至信箱，請確認信箱中的信件並按下驗證連結已完成註冊", preferredStyle: .alert)
            //按下按鈕後解除sinup view controller
            let okayAction = UIAlertAction(title: "了解惹", style: .cancel) { (action) in
                //解除signup view controller
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(okayAction)
            self.present(alertController, animated: true, completion: nil)
        } //createUser
    } //registerAccount
    
    //按下顯示密碼的按鈕後，密碼會顯示，並且圖片也轉成眼睛
    @IBAction func pressHidePasswordButton(_ sender: UIButton) {
        var password: UITextField = passwordTextField
        switch sender {
        case passwordButton:
            password = passwordTextField
        case reEnterPasswordButton:
            password = reEnterPasswordTextField
        default:
            break
        }
        let image =  password.isSecureTextEntry == true ? "eye" : "eye.slash"
        sender.setImage(UIImage(systemName: image), for: .normal)
        password.isSecureTextEntry = !password.isSecureTextEntry
    }
}
