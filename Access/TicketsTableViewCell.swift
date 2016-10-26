//
//  TicketsTableViewCell.swift
//  Access
//
//  Created by Adam Hegedus on 10/17/16.
//  Copyright © 2016 EnergyCAP, Inc. All rights reserved.
//

import UIKit

class TicketsTableViewCell: UITableViewCell {

    @IBOutlet weak var ticketIdLabel: UILabel!
    @IBOutlet weak var ticketDescLabel: UILabel!
    @IBOutlet weak var ticketCheckBox: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
