//
//  ArrowableTitleView.swift
//  Burpple2
//
//  Created by John Kuan on 14/8/17.
//  Copyright © 2017 Burpple Pte Ltd. All rights reserved.
//

import UIKit

@objc public protocol ArrowableTitleViewDelegate: NSObjectProtocol {
    func viewDidTapped(_ view: ArrowableTitleView, state: Bool)
}

final public class ArrowableTitleView: UIView {

    var delegate: ArrowableTitleViewDelegate!
    var selectedState: Bool = false

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFont(ofSize:17, weight: UIFont.Weight.medium)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Medium", size: 17)
        }
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        return label
    }()

    lazy var chevronView: ArrowImageView = {
        let imageV = ArrowImageView(template: true)
        imageV.tintColor = .white
        imageV.isHidden = true
        return imageV
    }()

    @available(iOS 9, *)
    lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.titleLabel, self.chevronView])
        stack.axis = .horizontal
        stack.spacing = 8.0
        stack.distribution = .fill
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stack)
        return stack
    }()

    // public function
    init(frame: CGRect, delegate: ArrowableTitleViewDelegate) {
        super.init(frame: frame)
        setupViews()
        self.delegate = delegate
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9, *) {
            heightAnchor.constraint(equalToConstant: 40.0).isActive = true
            stack.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            stack.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        } else {
            self.addSubview(titleLabel)
            self.addSubview(chevronView)
            
            
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]-(horizontalPadding)-[arrow]-|", options: [.alignAllCenterY], metrics: ["horizontalPadding": 15.0], views: ["label": titleLabel, "arrow" : chevronView]))
            
            titleLabel.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0))
            self.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
            self.addConstraint(NSLayoutConstraint(item: chevronView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0))
        }

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selected))
        addGestureRecognizer(tap)
        sizeToFit()
    }

    func toggle() {
        DispatchQueue.main.async {
            self.selectedState = !self.selectedState
            if self.selectedState {
                self.chevronView.upsideDown(true)
            } else {
                self.chevronView.normal(true)
            }
        }
    }

    public func setTitle(text: String, hideArrow: Bool) {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = text
        titleLabel.sizeToFit()
        chevronView.isHidden = hideArrow
        sizeToFit()
        if #available(iOS 10, *) {
            // skip
        } else {
            translatesAutoresizingMaskIntoConstraints = true
        }
    }
    
    public func setTitleColor(color: UIColor) {
        titleLabel.textColor = color
    }

    @objc func selected() {
        toggle()
        delegate.viewDidTapped(self, state: selectedState)
    }
}
