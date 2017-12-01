//
//  ArrowableTitleView.swift
//  Burpple2
//
//  Created by John Kuan on 14/8/17.
//  Copyright © 2017 Burpple Pte Ltd. All rights reserved.
//

import UIKit

protocol ArrowableTitleViewDelegate: NSObjectProtocol {
    func viewDidTapped(_ view: ArrowableTitleView, state: Bool)
}

class ArrowableTitleView: UIView {

    var delegate: ArrowableTitleViewDelegate!
    var selectedState: Bool = false

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.BPMediumFont(17.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }()

    lazy var chevronView: ArrowImageView = {
        let imageV = ArrowImageView(template: true)
        imageV.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        imageV.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        imageV.tintColor = .white
        imageV.translatesAutoresizingMaskIntoConstraints = false
        imageV.isHidden = true
        return imageV
    }()

    lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        stack.axis = .horizontal
        stack.spacing = 8.0
        stack.distribution = .fill
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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 40.0).isActive = true

        stack.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        stack.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(selected))
        addGestureRecognizer(tap)
        translatesAutoresizingMaskIntoConstraints = true
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

    func setTitle(text: String, hideArrow: Bool) {
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

    @objc func selected() {
        toggle()
        delegate.viewDidTapped(self, state: selectedState)
    }
}
