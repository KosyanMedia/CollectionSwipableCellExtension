//
//  CollectionSwipableCellHandler.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 14/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import Foundation

class CollectionSwipableCellHandler: NSObject {

    weak var delegate: CollectionSwipableCellExtensionDelegate?

    fileprivate let recognizer = UIPanGestureRecognizer()
    fileprivate let tapRecognizer = UITapGestureRecognizer()
    fileprivate let direction: UIUserInterfaceLayoutDirection
    fileprivate var layouterInProgress: SwipableCellLayouter?
    fileprivate let collection: SwipableActionsCollection

    init(collection: SwipableActionsCollection, direction: UIUserInterfaceLayoutDirection) {
        self.collection = collection
        self.direction = direction

        super.init()

        recognizer.addTarget(self, action: #selector(CollectionSwipableCellHandler.handlePan(_:)))
        recognizer.delegate = self

        tapRecognizer.addTarget(self, action: #selector(CollectionSwipableCellHandler.handleTap(_:)))
        tapRecognizer.delegate = self
    }

    deinit {
        layouterInProgress?.closeActions()
    }

    func applyToCollection() {
        if recognizer.view == nil {
            collection.view.addGestureRecognizer(recognizer)
        }

        if tapRecognizer.view == nil {
            collection.view.addGestureRecognizer(tapRecognizer)
        }
    }

    func removeFromCollection() {
        recognizer.view?.removeGestureRecognizer(recognizer)
        tapRecognizer.view?.removeGestureRecognizer(tapRecognizer)
    }

    func closeCellInProgress() {
        layouterInProgress?.closeActions()

        layouterInProgress = nil
    }

    fileprivate var directionFactor: CGFloat {
        return direction == .leftToRight ? 1 : -1
    }

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let swipeLocation = recognizer.location(in: collection.view)
        let swipedIndexPath = collection.indexPathForItem(at: swipeLocation)

        switch recognizer.state {
        case .began:
            if let swipedIndexPath = swipedIndexPath,
                let newItem = collection.item(at: swipedIndexPath) {
                if newItem.view != layouterInProgress?.item.view {
                    layouterInProgress?.closeActions()
                    let layout = delegate?.swipableActionsLayout(forItemAt: swipedIndexPath)
                    layouterInProgress = SwipableCellLayouter(item: newItem, layout: layout, direction: direction)
                }
            } else {
                layouterInProgress = nil

                return
            }

        // Start of the gesture.
        // You could remove any layout constraints that interfere
        // with changing of the position of the content view.
        case .changed:
            guard let layouterInProgress = layouterInProgress else {
                return
            }

            let translation = recognizer.translation(in: layouterInProgress.item.view)

            layouterInProgress.swipe(x: translation.x)
        case .ended:
            guard let layouterInProgress = layouterInProgress else {
                return
            }

            let velocity = recognizer.velocity(in: layouterInProgress.item.view)

            layouterInProgress.swipeFinished(withXVelocity: velocity.x)
        default:
            break;
        }
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        closeCellInProgress()
    }

    @objc func overlayGestureRecognizerAction(_ recognizer: UIGestureRecognizer) {
        closeCellInProgress()
    }

}

extension CollectionSwipableCellHandler: UIGestureRecognizerDelegate {

    @objc func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: collection.view)

            if abs(velocity.y) > abs(velocity.x)  {
                // vertical scrolling, hide active cell if any
                closeCellInProgress()

                return false
            }

            let swipeLocation = gestureRecognizer.location(in: collection.view)

            if let swipedIndexPath = collection.indexPathForItem(at: swipeLocation),
                delegate?.isSwipable(itemAt: swipedIndexPath) == true,
                let item = collection.item(at: swipedIndexPath) {

                if item.view === layouterInProgress?.item.view {
                    return true
                }

                return direction == .leftToRight ? velocity.x < 0 : velocity.x > 0
            }

            return false
        }

        if let gestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
            if gestureRecognizer === self.tapRecognizer {
                guard layouterInProgress != nil else {
                    return false
                }

                return true
            } else {
                // Per-cell tap recognizer: handle taps only when cellInProgress exists
                return layouterInProgress != nil
            }
        }

        return false
    }

}