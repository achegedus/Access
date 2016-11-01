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
        if let token = keychain.string(forKey: "refresh_token") {
            let client = A0Lock.shared().apiClient()
            
            client.fetchNewIdToken(withRefreshToken: token, parameters: nil, success: { (newToken) in
                // save the token
                
                client.fetchUserProfile(withIdToken: newToken.idToken, success: { (profile) in
                    //Just got a new id_token!
                    print("You're still logged in!");
                    print("TOKEN \(newToken.idToken)")
                    self.performSegue(withIdentifier: "loggedInSeque", sender: self)
                    
                    self.saveProfileDetails(profile: profile, token: newToken)
                    
                    self.getDelegateToken()
                    
                }, failure: { (error) in
                    // didn't get profile
                    
                    keychain.clearAll() //Cleaning stored values since they are no longer valid
                    //id_token is no longer valid.
                    //You should ask the user to login again!.
                    
                    let appDomain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: appDomain)

                    self.loginFormView.animate()
                })
                
            }, failure: { (error) in
                print("NOT LOGGED IN")
                keychain.clearAll() //Cleaning stored values since they are no longer valid
                //id_token is no longer valid.
                //You should ask the user to login again!.
                
                let appDomain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: appDomain)
                
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
    
    
    func getDelegateToken() {
        let keychain = A0SimpleKeychain(service: "Auth0")
        let client = A0Lock.shared().apiClient()
        
        if let token = keychain.string(forKey: "id_token") {
            let parameters = A0AuthParameters.new(with: [
                "id_token": token,
                A0ParameterAPIType: "firebase"
                ])
            
            client.fetchDelegationToken(with: parameters, success: { (payload) in
                print ("DELEGATE TOKEN: \(payload) ")
                let delegateToken = payload
                keychain.setString(delegateToken["id_token"] as! String, forKey: "delegate_token")
                
                // login to firebase
                FIRAuth.auth()?.signIn(withCustomToken: delegateToken["id_token"] as! String, completion: { (user, error) in
                    print("You're logged into firebase")
                })
                
            }, failure: { (error) in
                //something failed
                print ("NO DELEGATE TOKEN: \(error) ")
                
                let alert = UIAlertController(title: "Alert", message: "Ops chat is currently unavailable.  Please contact EnergyCAP Operations.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    
    func saveProfileDetails(profile : A0UserProfile, token : A0Token) {
        // set keychain values
        
        let userDefaults = UserDefaults.standard
        
        let keychain = A0SimpleKeychain(service: "Auth0")
        keychain.setString(token.idToken, forKey: "id_token")
        
        if let refreshToken = token.refreshToken {
            keychain.setString(refreshToken, forKey: "refresh_token")
        }
        
        keychain.setData(NSKeyedArchiver.archivedData(withRootObject: profile), forKey: "profile")
        
        var isAdmin = false
        isAdmin = (profile.userMetadata["isAdmin"] != nil && (profile.userMetadata["isAdmin"] as? Bool)!)
        userDefaults.set(isAdmin, forKey: "isAdmin")
        userDefaults.set(profile.userId, forKey: "user_id")
        userDefaults.set(profile.name, forKey: "fullname")
        userDefaults.set(profile.email, forKey: "email")
        userDefaults.set(profile.email, forKey: "user_id")
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
            
            self.saveProfileDetails(profile: profile, token: token)
            
            self.getDelegateToken()
            
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
