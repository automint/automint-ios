//
//  LabelTextCell.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 03/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class LabelTextCell: UITableViewCell {

    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var uncheckView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueTextField: QuantityTextField!
    @IBOutlet weak var valueTextFieldWidth: NSLayoutConstraint!
    @IBOutlet weak var bottomSepLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        checkImageView.layer.cornerRadius = 12.0
        uncheckView.layer.cornerRadius = 12.0
        uncheckView.layer.borderWidth = 1.0
        uncheckView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            self.checkImageView.hidden = false
            self.uncheckView.hidden = true
        } else {
            self.checkImageView.hidden = true
            self.uncheckView.hidden = false
        }
        
    }
    
}
