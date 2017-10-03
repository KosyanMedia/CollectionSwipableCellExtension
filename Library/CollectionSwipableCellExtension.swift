//
//  CollectionSwipableCellExtension.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 22/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import Foundation

@objc
public protocol CollectionSwipableCellLayout: class {
    var actionsView: UIView { get }
    func swipingAreaWidth() -> CGFloat
    func setupActionsView()
    func layoutActionsView()
}

@objc
public protocol CollectionSwipableCellExtensionDelegate: class {
    func isSwipable(itemAt indexPath: IndexPath) -> Bool
    func swipableActionsLayout(forItemAt indexPath: IndexPath) -> CollectionSwipableCellLayout?
}

@objcMembers
public class CollectionSwipableCellExtension: NSObject {

    public weak var delegate: CollectionSwipableCellExtensionDelegate? {
        didSet {
            handler?.delegate = delegate
        }
    }

    public var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                let direction: UIUserInterfaceLayoutDirection = isRtlLayoutDirection(of: collection.view) ? .rightToLeft : .leftToRight
                handler = CollectionSwipableCellHandler(collection: collection, direction: direction)
                handler?.delegate = delegate
                handler?.applyToCollection()
            } else {
                handler?.removeFromCollection()
                handler = nil
            }
        }
    }

    private let collection: SwipableActionsCollection
    private var handler: CollectionSwipableCellHandler?

    @objc(initWithCollectionView:)
    public init(with collectionView: UICollectionView) {
        self.collection = SwipableUICollectionView(collectionView: collectionView)
        super.init()
    }

    @objc(initWithTableView:)
    public init(with tableView: UITableView) {
        self.collection = SwipableUITableView(tableView: tableView)
        super.init()
    }

    public func closeAllActions() {
        handler?.closeCellInProgress()
    }

}

private func isRtlLayoutDirection(of view: UIView) -> Bool {
    if #available(iOS 9.0, *) {
        return UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft
    } else {
        let lang = Locale.current.languageCode
        return NSLocale.characterDirection(forLanguage: lang!) == .rightToLeft
    }
}
