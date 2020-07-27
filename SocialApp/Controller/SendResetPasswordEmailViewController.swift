//
//  ResetPasswordViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/11.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase

class SendResetPasswordEmailViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func resetPassword(sender:UIButton){
        //驗證email是否空白
        guard let emailaddress = emailTextField.text else {
            alert(title: "信箱不完整", message: "信箱請勿空白")
            return
        }
        
        //送出密碼重設的email
        Auth.auth().sendPasswordReset(withEmail: emailaddress) { (error) in
            let title = (error == nil) ? "重新設定密碼信件已寄出" : "密碼重設錯誤"
            let message = (error == nil) ? "已寄出信件，請確認信箱" : error?.localizedDescription
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
                if error == nil {
                    //解除鍵盤
                    self.view.endEditing(true)
                    //返回登入畫面
                    if let navController = self.navigationController{
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
            alertController.addAction(okayAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
