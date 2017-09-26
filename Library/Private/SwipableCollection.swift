//
//  SwipableCollection.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 22/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import Foundation

protocol SwipableActionsItem: class {
    var view: UIView { get }
    var contentView: UIView { get }
}

protocol SwipableActionsCollection: class {
    var view: UIView { get }
    func indexPathForItem(at location: CGPoint) -> IndexPath?
    func item(at indexPath: IndexPath) -> SwipableActionsItem?
}