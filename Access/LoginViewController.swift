//
//  LoginViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/12/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import Spring
import Lock
import SimpleKeychain
import FirebaseDatabase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: DesignableTextField!
    @IBOutlet weak var passwordTextField: DesignableTextField!
    
    @IBOutlet weak var loginFormView: DesignableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let keychain = A0SimpleKeychain(service: "Auth0")
        if let token = keychain.string(forKey: "id_token") {
            let client = A0Lock.shared().apiClient()
            client.fetchNewIdToken(withIdToken: token, parameters: nil, success: { (newToken) in
                // save the token
                keychain.setString(newToken.idToken, forKey: "id_token")
                
                //Just got a new id_token!
                print("You're still logged in!");
                print("TOKEN \(newToken.idToken)")
                self.performSegue(withIdentifier: "loggedInSeque", sender: self)
                
                let parameters = A0AuthParameters.new(with: [
                    "id_token": newToken.idToken,
                    A0ParameterAPIType: "firebase"
                ])
                
                
                client.fetchDelegationToken(with: parameters, success: { (payload) in
                    print ("DELEGATE TOKEN: \(payload) ")
                    let delegateToken = payload
                    keychain.setString(delegateToken["id_token"] as! String, forKey: "delegate_token")
                    
                    // login to firebase
                    FIRAuth.auth()?.signIn(withCustomToken: delegateToken["id_token"] as! String, completion: { (user, error) in
                        print("You're logged into firebase \(newToken.idToken) : \(error)")
                    })
                    
                }, failure: { (error) in
                    //something failed
                    print ("NO DELEGATE TOKEN: \(error) ")
                })
            
                
                
                
            }, failure: { (error) in
                print("NOT LOGGED IN")
                keychain.clearAll() //Cleaning stored values since they are no longer valid
                //id_token is no longer valid.
                //You should ask the user to login again!.
                self.loginFormView.animate()
            })
        } else {
            self.loginFormView.animate()
            print("No id_token FOUND")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonWasPressed(_ sender: AnyObject) {
        
        var email:String = usernameTextField.text!;
        
        if (!email.hasSuffix("@energycap.com")) {
            email = usernameTextField.text! + "@energycap.com"
        }
        
        let password = passwordTextField.text
        let lock = A0Lock.shared()
        let client = lock.apiClient()
        let parameters = A0AuthParameters(dictionary: [A0ParameterConnection : "EnergyCAP-ADFS"])
        
        
        client.login(withEmail: email, passcode: password!, parameters: parameters, success: { (profile, token) in
            
            print("We did it!. Logged in with Auth0. \(profile.userMetadata)")
            let keychain = A0SimpleKeychain(service: "Auth0")
            keychain.setString(token.idToken, forKey: "id_token")
            keychain.setString(profile.userId, forKey: "user_id")
            keychain.setString(profile.name, forKey: "fullname")
            keychain.setString(profile.email!, forKey: "email")
            
            var userData = profile.userMetadata as NSDictionary? as? [AnyHashable: Any] ?? [:]
            let isAdmin = (userData.isAdmin)! as Bool
//            keychain.setValue(profile.userMetadata.isAdmin, forKey: "isAdmin")
            
            // set keychain values
            if let refreshToken = token.refreshToken {
                keychain.setString(refreshToken, forKey: "refresh_token")
            }
            
            keychain.setData(NSKeyedArchiver.archivedData(withRootObject: profile), forKey: "profile")
            
            self.usernameTextField.text = "";
            self.passwordTextField.text = "";
            
            self.performSegue(withIdentifier: "loggedInSeque", sender: sender)
        }) { (Error) in
            print("Oops something went wrong: \(Error)")
            self.loginFormView.animation.removeAll()
            self.loginFormView.animation = "shake"
            self.loginFormView.animate()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func LogoutFromSettingsUnwind(segue:UIStoryboardSegue) {
        self.loginFormView.animation.removeAll()
        self.loginFormView.animation = "fadeInUp"
        self.loginFormView.animate()
    }

}
