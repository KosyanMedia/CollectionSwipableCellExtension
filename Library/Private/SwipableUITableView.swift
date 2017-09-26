//
//  SwipableUITableView.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 22/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import UIKit

class SwipableUITableView: SwipableActionsCollection {

    let view: UIView

    private let tableView: UITableView

    init(tableView: UITableView) {
        self.view = tableView
        self.tableView = tableView
    }

    func indexPathForItem(at location: CGPoint) -> IndexPath? {
        return tableView.indexPathForRow(at: location)
    }

    func item(at indexPath: IndexPath) -> SwipableActionsItem? {
        if let cell = tableView.cellForRow(at: indexPath) {
            return SwipableItemForUITableView(cell: cell)
        }

        return nil
    }

}

class SwipableItemForUITableView: SwipableActionsItem {

    let view: UIView
    let contentView: UIView

    init(cell: UITableViewCell) {
        self.view = cell
        self.contentView = cell.contentView
    }

}