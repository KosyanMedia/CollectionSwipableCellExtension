//
//  UITableViewCell+CollectionSwipableCellExtension.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 30/01/2018.
//  Copyright © 2018 Aviasales. All rights reserved.
//

import UIKit

private var kSwipableHandlerAssociatedKey = "swipableHandler"

public extension UITableViewCell {

    @objc public func resetSwipableActions() {
        swipableHandler?.removeCurrentLayouterBeforeCellReusing()
    }

    internal weak var swipableHandler: CollectionSwipableCellHandler? {
        set {
            objc_setAssociatedObject(self, &kSwipableHandlerAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &kSwipableHandlerAssociatedKey) as? CollectionSwipableCellHandler
        }
    }

}
