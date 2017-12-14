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

    var actionsAreClosed: Bool {
        return cellTranslationX == 0
    }

    private let layout: CollectionSwipableCellLayout?

    private var wrapperView: UIView?
    private var containerView: UIView?

    private var originSwipePosition: CGFloat = 0
    private var maxActionsVisibleWidth: CGFloat = 0

    private var swipeIsFinished = true

    private var finishType: FinishAnimationType = .undefined

    private let offsetCollector = OffsetCollector()

    private var hapticGeneratorObject: Any?
    @available(iOS 10.0, *)
    private var hapticGenerator: UIImpactFeedbackGenerator? {
        guard layout?.hapticFeedbackIsEnabled() == true else {
            return nil
        }

        if hapticGeneratorObject == nil {
            hapticGeneratorObject = UIImpactFeedbackGenerator(style: .medium)
        }

        return hapticGeneratorObject as? UIImpactFeedbackGenerator
    }

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

    func closeAndRemoveActions(animated: Bool) {
        if animated {
            performFinishAnimation(toValue: 0) {
                self.removeButtonsFromCell()
            }
        } else {
            removeButtonsFromCell()
        }
    }

    func swipe(x: CGFloat) {
        if swipeIsFinished {
            originSwipePosition = swipePosition

            if #available(iOS 10.0, *) {
                hapticGenerator?.prepare()
            }
        }
        swipePosition = originSwipePosition + x * directionFactor;
        swipeIsFinished = false
    }

    func swipeFinished() {
        switch finishType {
        case .fullOpen:
            performFinishAnimation(toValue:  -swipeWidth(), completion: {
                self.layout?.cellDidFullOpen()
            })
        case .open:
            performFinishAnimation(toValue: -maxActionsVisibleWidth)
        case .closed:
            performFinishAnimation(toValue: 0)
        default:
            return
        }

        swipeIsFinished = true
    }

    private var isOpeningDirectionPreviousValue = false

    private func onSwipe(prevValue: CGFloat) {
        let isOpeningDirection: Bool
        if swipePosition < prevValue {
            isOpeningDirection = true
        } else if swipePosition == prevValue {
            isOpeningDirection = isOpeningDirectionPreviousValue
        } else {
            isOpeningDirection = false
        }
        isOpeningDirectionPreviousValue = isOpeningDirection

        let defaultValue = swipePosition * directionFactor
        let expectedFinishType: FinishAnimationType

        switch (swipePosition, cellTranslationX, isOpeningDirection) {
        case (_, direction == .leftToRight ? 0 ... CGFloat.infinity : -CGFloat.infinity ... 0, false): // opposite bounce
            cellTranslationX = directionFactor * easeOut(value: swipePosition,
                                                         startValue: 0,
                                                         endValue: item.view.bounds.width,
                                                         asymptote: item.view.bounds.width / 6)
            expectedFinishType = .closed

        case (_, _, false): // close
            cellTranslationX = defaultValue
            expectedFinishType = .closed

        case (-CGFloat.infinity ... -item.view.bounds.width * 0.75, direction == .leftToRight ? -CGFloat.infinity ... -maxActionsVisibleWidth : maxActionsVisibleWidth ... CGFloat.infinity, true):// full open
            if finishType != .fullOpen {
                if #available(iOS 10.0, *) {
                    hapticGenerator?.impactOccurred()
                }

                UIView.animate(withDuration: 0.2, animations: {
                    self.cellTranslationX = defaultValue
                    self.layoutActions()
                })
            } else {
                cellTranslationX = defaultValue
            }
            expectedFinishType = .fullOpen

        case (_, direction == .leftToRight ? -CGFloat.infinity ... -maxActionsVisibleWidth : maxActionsVisibleWidth ... CGFloat.infinity, true):// open with bounce
            cellTranslationX = directionFactor * easeOut(value: swipePosition,
                                                         startValue: -maxActionsVisibleWidth,
                                                         endValue: -item.view.bounds.width,
                                                         asymptote: -maxActionsVisibleWidth + -item.view.bounds.width / 6)
            expectedFinishType = .open

        case (_, direction == .leftToRight ? -maxActionsVisibleWidth ... 0 : 0 ... maxActionsVisibleWidth, true): // open
            cellTranslationX = defaultValue
            expectedFinishType = .open

        default:
            cellTranslationX = defaultValue
            expectedFinishType = .closed
        }

        layoutActions()

        offsetCollector.add(offset: abs(swipePosition - prevValue), for: expectedFinishType)

        let limitOffset = item.view.bounds.width * kCompletionOffsetFactor
        switch (expectedFinishType, offsetCollector.offset(for: expectedFinishType)) {
        case (.fullOpen, _),
             (.open, limitOffset ... CGFloat.infinity),
             (.closed, limitOffset ... CGFloat.infinity):
            finishType = expectedFinishType
        default:
            if finishType == .undefined {
                finishType = .closed
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

            layoutActions()
        }
    }

    private func layoutActions() {
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

        layout?.layoutActionsView()
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

    private func swipeWidth() -> CGFloat {
        return item.view.bounds.width + (layout?.swipingAreaInset() ?? 0)
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
    case closed
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
