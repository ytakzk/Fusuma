//
//  FSAlbumSelectionTableViewCell.swift
//  Burpple2
//
//  Created by John Kuan on 14/8/17.
//  Copyright © 2017 Burpple Pte Ltd. All rights reserved.
//

import UIKit
import Photos

final class FSAlbumSelectionTableViewCell: UITableViewCell {

    static let rowHeight: CGFloat = 87.0
    static let imageSize: CGFloat = FSAlbumSelectionTableViewCell.rowHeight - 12.0

    fileprivate lazy var mainLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor(red: 85.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
        label.numberOfLines = 1
        self.contentView.addSubview(label)
        return label
    }()

    fileprivate lazy var subLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = UIColor(red: 85.0 / 255.0, green: 85.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
        label.numberOfLines = 1
        self.contentView.addSubview(label)
        return label
    }()

    
    lazy var mainimageView: UIImageView = {
        let imageV = UIImageView(frame: .zero)
        if #available(iOS 9.0, *) {
            imageV.heightAnchor.constraint(equalToConstant: FSAlbumSelectionTableViewCell.imageSize).isActive = true
            imageV.widthAnchor.constraint(equalTo: imageV.heightAnchor).isActive = true
        } else {
            let constraints = [
                NSLayoutConstraint(item: imageV, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: FSAlbumSelectionTableViewCell.imageSize),
                NSLayoutConstraint(item: imageV, attribute: .width, relatedBy: .equal, toItem: imageV, attribute: .height, multiplier: 1.0, constant: 0),
                ]
            imageV.addConstraints(constraints)
        }
        
        imageV.translatesAutoresizingMaskIntoConstraints = false
        imageV.contentMode = .scaleAspectFit
        self.contentView.addSubview(imageV)
        return imageV
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupViews()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    fileprivate func setupViews() {
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 1.0)
            return view
        }()

        if #available(iOS 9.0, *) {
            mainimageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0).isActive = true
            mainimageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
            
            mainLabel.leftAnchor.constraint(equalTo: mainimageView.rightAnchor, constant: 15.0).isActive = true
            mainLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -5.0).isActive = true
            mainLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10.0).isActive = true
            
            subLabel.leftAnchor.constraint(equalTo: mainLabel.leftAnchor).isActive = true
            subLabel.rightAnchor.constraint(equalTo: mainLabel.rightAnchor).isActive = true
            subLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10.0).isActive = true
        } else {
            let mainImageViewConstraints = [
                NSLayoutConstraint(item: mainimageView, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 12.0),
                NSLayoutConstraint(item: mainimageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0),
            ]
            contentView.addConstraints(mainImageViewConstraints)
            
            let mainLabelConstraints = [
                NSLayoutConstraint(item: mainLabel, attribute: .left, relatedBy: .equal, toItem: mainLabel, attribute: .right, multiplier: 1.0, constant: 15.0),
                NSLayoutConstraint(item: mainLabel, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: -5.0),
                NSLayoutConstraint(item: mainLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: -10.0),
                ]
            contentView.addConstraints(mainLabelConstraints)
            
            let subLabelConstraints = [
                NSLayoutConstraint(item: subLabel, attribute: .left, relatedBy: .equal, toItem: mainLabel, attribute: .left, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subLabel, attribute: .right, relatedBy: .equal, toItem: mainLabel, attribute: .right, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: subLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 10.0),
                ]
            contentView.addConstraints(subLabelConstraints)
        }
    }

    public func setup(albumDetails: AlbumModel, image: UIImage?) {
        let name = albumDetails.collection.localizedTitle
        mainLabel.text = name
        accessibilityLabel = name
        subLabel.text = "\(albumDetails.collection.photosCount)"
        mainimageView.image = image
        //        accessibilityIdentifier = identifier
    }

    public func updateImage(image: UIImage?) {
        mainimageView.image = image
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
