//
//  ChatViewController.swift
//  Access
//
//  Created by Adam Hegedus on 10/14/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var username:String = ""
    var messages : [JSQMessage] = []
    let userDefaults = UserDefaults.standard
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let rootRef = FIRDatabase.database().reference(fromURL: "https://energycap-access.firebaseio.com/")
    
    var messageRef = FIRDatabase.database().reference(fromURL: "https://energycap-access.firebaseio.com/").child("messages")
    
    var userIsTypingRef: FIRDatabaseReference!
    private var localTyping = false
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    
    private func observeTyping() {
        let typingIndicatorRef = rootRef.child(username).child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(username)
        userIsTypingRef.onDisconnectRemoveValue()
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        return nil
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImage(
            with: UIColor.init(colorLiteralRed: 0.76, green: 0.80, blue: 0.16, alpha: 1.00))
        
        incomingBubbleImageView = factory.incomingMessagesBubbleImage(
            with: UIColor.jsq_messageBubbleLightGray())
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource? {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId() { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    
    func addMessage(id: String, text: String, sendDate: Date) {
//        let message = JSQMessage(senderId: id, displayName: "", text: text)
        let message = JSQMessage(senderId: id, senderDisplayName: "", date: sendDate, text: text)
        messages.append(message)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == self.senderId() {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.black
        }
        
        return cell
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        setupBubbles()
        
        // No avatars!
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        print("XXXXXX - senderID: \(senderId())")
        
        messageRef = rootRef.child(username).child("messages")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeMessages()
        observeTyping()
        
        self.inputToolbar.contentView!.textView!.becomeFirstResponder()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func senderId() -> String {
        
        let userid = userDefaults.object(forKey: "fullname") as! String
        return userid.replacingOccurrences(of: " ", with: "_")
    }
    
    
    override func senderDisplayName() -> String {
        return userDefaults.object(forKey: "fullname") as! String
    }
 

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        let itemRef = messageRef.childByAutoId()
        let now = Date()
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "sendDate": df.string(from: now)
        ]
        itemRef.setValue(messageItem)
        
//        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        isTyping = false
    }
    
    
    private func observeMessages() {
        let messagesQuery = messageRef.queryLimited(toLast: 25)
        
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        
        messagesQuery.observe(.childAdded) { (snapshot: FIRDataSnapshot!) in
            if let data = snapshot.value as? [String:String] {
                print(data)
                let id = data["senderId"]! as String
                let text = data["text"]!  as String
                let sendDate = df.date(from: data["sendDate"]!)
                
                self.addMessage(id: id, text: text, sendDate: sendDate!)
            }
            
            self.finishReceivingMessage()
        }
    }
    
}
