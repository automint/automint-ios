//
//  FooterCell.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 04/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class FooterCell: UITableViewCell {

    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var uncheckView: UIView!
    @IBOutlet weak var nameText: NameTextField!
    @IBOutlet weak var valueText: QuantityTextField!
    @IBOutlet weak var addButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        checkImageView.layer.cornerRadius = 12.0
        uncheckView.layer.cornerRadius = 12.0
        uncheckView.layer.borderWidth = 1.0
        uncheckView.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        nameText.textAlignment = .Left
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
