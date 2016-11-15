//
//  ContactTableViewCell.swift
//  Access
//
//  Created by Adam Hegedus on 11/7/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit
import AvatarImageView

struct TableAvatarImageConfig: AvatarImageViewConfiguration {
    let shape: Shape = .circle
    let bgColor: UIColor? = UIColor.init(hex: "#C1CF00")
}


class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var userImage: AvatarImageView! {
        didSet {
            userImage.configuration = TableAvatarImageConfig()
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
