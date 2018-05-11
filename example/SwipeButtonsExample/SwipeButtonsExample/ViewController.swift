//
//  ViewController.swift
//  SwipeButtonsExample
//
//  Created by Dmitry Ryumin on 06/04/2018.
//  Copyright © 2018 aviasales. All rights reserved.
//

import UIKit
import CollectionSwipableCellExtension

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var cells = [String]()
    private var swipableExtension: CollectionSwipableCellExtension?

    override func viewDidLoad() {
        super.viewDidLoad()

        (0 ..< 20).forEach { cells.append("Title of cell #\($0)") }

        tableView.delegate = self
        tableView.dataSource = self

        swipableExtension = CollectionSwipableCellExtension(with: tableView)
        swipableExtension?.delegate = self
        swipableExtension?.isEnabled = true
    }

    private func deleteCell(atIndexPath indexPath: IndexPath) {
        tableView.beginUpdates()
        cells.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

}

extension ViewController: UITableViewDelegate {

}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "testCell") as! TableCell
        cell.titleLabel.text = cells[indexPath.row]

        return cell
    }

}

extension ViewController: CollectionSwipableCellExtensionDelegate {

    func isSwipable(itemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func swipableActionsLayout(forItemAt indexPath: IndexPath) -> CollectionSwipableCellLayout? {
        let actionLayout = CollectionSwipableCellOneButtonLayout(buttonWidth: 100, insets: .zero, direction: .leftToRight)
        actionLayout.action = { [weak self] in
            self?.deleteCell(atIndexPath: indexPath)
        }

        return actionLayout
    }

}

class TableCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        resetSwipableActions()
    }

}
