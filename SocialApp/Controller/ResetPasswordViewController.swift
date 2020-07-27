//
//  ResetPasswordViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/18.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var reEnterNewPasswordTextField: UITextField!
    @IBOutlet weak var oldPasswordButton: UIButton!
    @IBOutlet weak var newPasswordButton: UIButton!
    @IBOutlet weak var reEnterNewpasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func resetPassword(sender:UIButton){
        //輸入驗證
        guard let oldPassword = oldPasswordTextField.text, !oldPassword.isEmpty ,let newPassword = newPasswordTextField.text, !newPassword.isEmpty,let reEnterNewPassword = reEnterNewPasswordTextField.text, !reEnterNewPassword.isEmpty else {
            alert(title: "欄位輸入不完整", message: "密碼欄位請勿空白")
            return
        }
        //檢查密碼輸入是否一致
        guard newPassword == reEnterNewPassword else {
            alert(title: "密碼輸入錯誤", message: "密碼輸入不一致")
            return
        }
        //再更改密碼前若離驗證時間太久，會出現FIRAuthErrorCodeCredentialTooOld錯誤，所以要先重新驗證一次
        let user = Auth.auth().currentUser
        guard let email = user?.email else {
            print("從firebase取信箱失敗")
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
    
        //重新驗證user
        user?.reauthenticate(with: credential, completion: { (result, error) in
            guard error == nil else {
                print("error: \(error!.localizedDescription)")
                return
            }
            //驗證通過若無錯誤產生，就更改密碼
            Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                guard error == nil else {
                    print("變更密碼失敗 \(error!.localizedDescription)")
                    return
                }
                
                //跳出視窗提示變更完成，並返回MainViewController
                let alertController = UIAlertController(title: "變更成功", message: "密碼更動完成", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
                    if error == nil {
                        //解除鍵盤
                        self.view.endEditing(true)
                        
                        //返回登入畫面
                        if self.navigationController != nil{
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
                
            })
        })
        
    } //reset Password
    
    //按下顯示密碼的按鈕後，密碼會顯示，並且圖片也轉成眼睛
    @IBAction func pressHidePasswordButton(_ sender: UIButton) {
        var passwordTextField: UITextField = oldPasswordTextField
        switch sender {
        case oldPasswordButton:
            passwordTextField = oldPasswordTextField
        case newPasswordButton:
            passwordTextField = newPasswordTextField
        case reEnterNewpasswordButton:
            passwordTextField = reEnterNewPasswordTextField
        default:
            break
        }
        let image =  passwordTextField.isSecureTextEntry == true ? "eye" : "eye.slash"
        sender.setImage(UIImage(systemName: image), for: .normal)
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
    }
}
