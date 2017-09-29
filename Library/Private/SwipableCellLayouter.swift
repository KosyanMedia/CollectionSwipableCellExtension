//
//  SwipableCellLayouter.swift
//  AviasalesComponents
//
//  Created by Dmitry Ryumin on 19/09/2017.
//  Copyright © 2017 Aviasales. All rights reserved.
//

import Foundation

private let kActionsWrapperViewTag = 9
private let kDefaultActionsWidth: CGFloat = 100
private let kCompletionOffsetFactor: CGFloat = 0.05

class SwipableCellLayouter {

    let item: SwipableActionsItem

    private let layout: CollectionSwipableCellLayout?

    private var wrapperView: UIView?
    private var containerView: UIView?

    private var originSwipePosition: CGFloat = 0
    private var maxActionsVisibleWidth: CGFloat = 0

    private var swipeIsFinished = true

    private var finishType: FinishAnimationType = .undefined

    private let offsetCollector = OffsetCollector()

    private var swipePosition: CGFloat = 0 {
        didSet {
            onSwipe(prevValue: oldValue)
        }
    }

    private var cellTranslationX: CGFloat {
        get {
            if #available(iOS 9, *) {
                return item.contentView.frame.origin.x
            } else {
                return item.contentView.transform.tx
            }
        }
        set {
            if #available(iOS 9, *) {
                item.contentView.frame.origin.x = newValue
            } else {
                item.contentView.transform = CGAffineTransform(translationX: newValue, y: 0)
            }
        }
    }

    private let direction: UIUserInterfaceLayoutDirection

    init(item: SwipableActionsItem, layout: CollectionSwipableCellLayout?, direction: UIUserInterfaceLayoutDirection) {
        self.item = item
        self.layout = layout
        self.direction = direction

        maxActionsVisibleWidth = layout?.swipingAreaWidth() ?? kDefaultActionsWidth
        setupViews()
    }

    deinit {
        removeButtonsFromCell()
    }

    func closeActions() {
        performFinishAnimation(toValue: 0) {
            self.removeButtonsFromCell()
        }
    }

    func swipe(x: CGFloat) {
        if swipeIsFinished {
            originSwipePosition = swipePosition
        }
        swipePosition = originSwipePosition + x * directionFactor;
        swipeIsFinished = false
    }

    func swipeFinished() {
        switch finishType {
        case .fullOpen:
            performFinishAnimation(toValue:  -item.view.bounds.width, completion: {
                self.layout?.cellDidFullOpen()
            })
        case .open:
            performFinishAnimation(toValue: -maxActionsVisibleWidth)
        case .close:
            performFinishAnimation(toValue: 0)
        default:
            return
        }

        swipeIsFinished = true
    }

    private func onSwipe(prevValue: CGFloat) {
        let isOpeningDirection = swipePosition <= prevValue
        let defaultValue = swipePosition * directionFactor
        let supposedFinishType: FinishAnimationType

        switch (swipePosition, cellTranslationX, isOpeningDirection) {
        case (_, _, false): // close
            print("close")
            cellTranslationX = defaultValue
            supposedFinishType = .close

        case (-CGFloat.infinity ... -item.view.bounds.width * 0.75, -CGFloat.infinity ... -maxActionsVisibleWidth, true):// full open
            print("full open")
            if finishType != .fullOpen {
                UIView.animate(withDuration: 0.2, animations: {
                    self.cellTranslationX = defaultValue
                    self.layoutActions(inFullOpenArea: false)
                })
            } else {
                cellTranslationX = defaultValue
            }
            supposedFinishType = .fullOpen

        case (_, -CGFloat.infinity ... -maxActionsVisibleWidth, true):// open with bounce
            print("bounce open")
            cellTranslationX = directionFactor * easeOut(value: swipePosition,
                                                         startValue: -maxActionsVisibleWidth,
                                                         endValue: -item.view.bounds.width,
                                                         asymptote: -maxActionsVisibleWidth + -item.view.bounds.width / 6)
            supposedFinishType = .open

        case (_, -maxActionsVisibleWidth ... 0, true): // open
            print("open")
            cellTranslationX = defaultValue
            supposedFinishType = .open

        default:
            print("default")
            cellTranslationX = defaultValue
            supposedFinishType = .close
        }

        layoutActions(inFullOpenArea: false)

        offsetCollector.add(offset: abs(swipePosition - prevValue), for: supposedFinishType)

        let limitOffset = item.view.bounds.width * kCompletionOffsetFactor
        switch (supposedFinishType, offsetCollector.offset(for: supposedFinishType)) {
        case (.fullOpen, _),
             (.open, limitOffset ... CGFloat.infinity),
             (.close, limitOffset ... CGFloat.infinity):
            finishType = supposedFinishType
        default:
            if finishType == .undefined {
                finishType = .close
            }
        }
    }

    private func removeButtonsFromCell() {
        swipePosition = 0

        if let wrapperView = item.view.viewWithTag(kActionsWrapperViewTag) {
            wrapperView.removeFromSuperview()
        }
    }

    private func setupViews() {
        wrapperView = item.view.viewWithTag(kActionsWrapperViewTag)

        if wrapperView == nil {
            let actionsViewWrapper = UIView(frame: item.view.bounds)
            actionsViewWrapper.tag = kActionsWrapperViewTag
            actionsViewWrapper.clipsToBounds = true
            actionsViewWrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            item.view.addSubview(actionsViewWrapper)
            item.view.sendSubview(toBack: actionsViewWrapper)

            wrapperView = actionsViewWrapper

            let actionsContainerView = UIView()
            actionsViewWrapper.addSubview(actionsContainerView)

            containerView = actionsContainerView

            if let layout = layout {
                actionsContainerView.addSubview(layout.actionsView)
                layout.setupActionsView()
            }

            layoutActions(inFullOpenArea: false)
        }
    }

    private func layoutActions(inFullOpenArea: Bool) {
        guard let containerView = containerView else {
            return
        }

        let width = -cellTranslationX * directionFactor

        if direction == .leftToRight {
            containerView.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
            containerView.frame = CGRect(x: item.view.bounds.width - width, y: 0, width: width, height: item.view.bounds.height)
        } else {
            containerView.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
            containerView.frame = CGRect(x: 0, y: 0, width: width, height: item.view.bounds.height)
        }

        layout?.layoutActionsView(inFullOpenArea: inFullOpenArea)
    }

    private func performFinishAnimation(toValue value: CGFloat, completion: (() -> Void)? = nil) {
        guard swipePosition != value else {
            completion?()
            return
        }

        struct FrameInfo {
            let duration: Double
            let value: CGFloat
        }

        let animationBlock = { (value: CGFloat) -> Void in
            self.swipePosition = value
            self.item.view.layoutIfNeeded()
        }

        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction, .calculationModeCubic], animations: {
            let bounceValue = self.item.view.bounds.width * 0.03

            let frame1 = FrameInfo(
                duration: 0.4,
                value: value >= 0 ? value + bounceValue * 0.9 : value - bounceValue * 0.9
            )
            let frame2 = FrameInfo(
                duration: 0.2,
                value: value >= 0 ? value + bounceValue : value - bounceValue
            )
            let frame3 = FrameInfo(
                duration: 0.1,
                value: frame2.value + (value - frame2.value) * 0.5
            )
            let frame4 = FrameInfo(
                duration: 0.3,
                value: value
            )

            let frameInfos = [frame1, frame2, frame3, frame4]

            var frameStart: Double = 0
            for frameInfo in frameInfos {
                UIView.addKeyframe(withRelativeStartTime: frameStart, relativeDuration: frameInfo.duration, animations: {
                    animationBlock(frameInfo.value)
                })

                frameStart = frameStart + frameInfo.duration
            }
        }) { (finished) in
            completion?()
        }
    }

    fileprivate var directionFactor: CGFloat {
        return direction == .leftToRight ? 1 : -1
    }

}

private func easeOut(value: CGFloat, startValue: CGFloat, endValue: CGFloat, asymptote: CGFloat) -> CGFloat {
    let t = (value - startValue) / (endValue - startValue) //to 0...1
    let easeResult = t * (2 - t) //quad ease out

    let normalizedAsymptote = asymptote - startValue

    return startValue + easeResult * normalizedAsymptote
}

private enum FinishAnimationType {
    case fullOpen
    case open
    case close
    case undefined
}

private class OffsetCollector {

    private var offset: CGFloat = 0
    private var type: FinishAnimationType = .undefined

    func add(offset: CGFloat, for type: FinishAnimationType) {
        if self.type == type {
            self.offset += offset
        } else {
            self.offset = offset
        }
        self.type = type
    }

    func offset(for type: FinishAnimationType) -> CGFloat {
        return self.type == type ? self.offset : 0
    }

}
