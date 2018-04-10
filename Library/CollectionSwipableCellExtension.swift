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
    func swipingAreaInset() -> CGFloat
    func setupActionsView()
    func layoutActionsView()
    func cellDidFullOpen()
    func hapticFeedbackIsEnabled() -> Bool
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

        startHandlingViewWindow()
    }

    @objc(initWithTableView:)
    public init(with tableView: UITableView) {
        self.collection = SwipableUITableView(tableView: tableView)
        super.init()

        startHandlingViewWindow()
    }

    public func closeAllActions() {
        handler?.closeCellInProgress()
    }

    // MARK: Handle move out of window

    private class AnchorView: UIView {

        var emptyWindowHandler: (() -> (Void))?

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)

            if let emptyWindowHandler = emptyWindowHandler, newWindow == nil {
                emptyWindowHandler()
            }
        }

    }

    private func startHandlingViewWindow() {
        let anchorView = AnchorView(frame: .zero)
        anchorView.alpha = 0
        anchorView.emptyWindowHandler = { [weak self] in
            self?.closeAllActions()
        }

        collection.view.addSubview(anchorView)
    }

}

internal class SwipableHandlerWrapper {

    private(set) weak var handler: CollectionSwipableCellHandler?

    init(handler: CollectionSwipableCellHandler) {
        self.handler = handler
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
