//
//  AvatarImageData.swift
//  Access
//
//  Created by Adam Hegedus on 11/15/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import Foundation
import AvatarImageView

struct AvatarImageData : AvatarImageViewDataSource {
    
    var name: String
    var avatar: UIImage?
    
    init(inputName: String) {
        name = inputName
    }
    
}
