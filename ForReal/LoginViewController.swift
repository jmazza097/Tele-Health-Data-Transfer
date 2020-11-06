//
//  LoginViewController.swift
//  ForReal
//
//  Created by Glen Evans on 10/7/20.
//  Copyright © 2020 Jack Mazza. All rights reserved.
//

import SwiftUI
import FirebaseUI
import UIKit


class LoginViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func loginTap(_ sender: UIButton) {
        //Get Default auth UI
            let authUI = FUIAuth.defaultAuthUI()

            // Check that it isn't nil
            guard authUI != nil else {
                return
            }

            //set Delegate
        authUI?.delegate = (self as FUIAuthDelegate)
            authUI?.providers = [FUIEmailAuth()]

            //Get reference to auth UI
            let authViewController = authUI!.authViewController()
            present(authViewController, animated: true, completion: nil)
        }
    
    
}
extension LoginViewController: FUIAuthDelegate {

func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {

    // Check for error
    guard error == nil else {
        return
        }
    performSegue(withIdentifier: "goHome", sender: self)

    }
}
