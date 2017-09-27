//
//  CollectionSwipableCellOneButtonLayout.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 22/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import Foundation

private let kButtonDefaultTitle = "Delete"
private let kButtonDefaultBackgroundColor = UIColor.white

@objcMembers
open class CollectionSwipableCellOneButtonLayout: NSObject, CollectionSwipableCellLayout {

    public let actionsView = UIView()

    public let button = UIButton(type: .system)

    public let direction: UIUserInterfaceLayoutDirection

    private let buttonWidth: CGFloat
    private let insets: UIEdgeInsets
    private let action: () -> Void

    public func swipingAreaWidth() -> CGFloat {
        return buttonWidth + insets.left + insets.right
    }

    public init(buttonWidth: CGFloat, insets: UIEdgeInsets, direction: UIUserInterfaceLayoutDirection, action: @escaping () -> Void) {
        self.buttonWidth = buttonWidth
        self.insets = insets
        self.direction = direction
        self.action = action

        button.setTitle(kButtonDefaultTitle, for: .normal)
        button.setBackgroundImage(UIImage(color: kButtonDefaultBackgroundColor), for: .normal)
    }

    open func setupActionsView() {
        actionsView.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
        actionsView.addSubview(button)

        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }

    open func layoutActionsView(inFullOpenArea: Bool) {
        guard let container = actionsView.superview else {
            return
        }

        let width = container.bounds.width - insets.left - insets.right
        let height = container.bounds.height - insets.top - insets.bottom

        actionsView.frame = CGRect(x: (direction == .leftToRight ? insets.left : insets.right), y: insets.top, width: width, height: height)

        let fullWidth = swipingAreaWidth() - insets.left - insets.right

        actionsView.alpha = width / fullWidth

        let buttonWidth = actionsView.bounds.width < fullWidth ? fullWidth : actionsView.bounds.width
        button.frame = CGRect(x: actionsView.bounds.width - buttonWidth, y: 0, width: buttonWidth, height: actionsView.bounds.height)
    }

    @objc private func buttonAction(_ sender: Any) {
        action()
    }

}
