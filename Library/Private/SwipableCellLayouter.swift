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

    private var isFullOpenArea = false//XXX need?

    private var swipePosition: CGFloat = 0 {
        didSet {
            print("###SWIPE: \(swipePosition)")//XXX
            let isActionsOpening = swipePosition <= 0

            if isActionsOpening {
                let isActionsNotOpen = swipePosition >= -maxActionsVisibleWidth
                let isReadyToShowFullButton = swipePosition <= -item.view.bounds.width * 0.85

                if isActionsNotOpen || isReadyToShowFullButton {
                    let value = swipePosition * directionFactor

                    if !isFullOpenArea && isReadyToShowFullButton {
                        UIView.animate(withDuration: 0.2, animations: {//XXX
                            self.cellTranslationX = value
                            self.layoutActions(inFullOpenArea: false)
                        })
                    } else {
                        cellTranslationX = value
                    }
                } else {
                    cellTranslationX = directionFactor * easeOut(value: swipePosition,
                                                                 startValue: -maxActionsVisibleWidth,
                                                                 endValue: -item.view.bounds.width,
                                                                 asymptote: -maxActionsVisibleWidth + -item.view.bounds.width / 6)
                }

                isFullOpenArea = isReadyToShowFullButton
            } else {
                cellTranslationX = directionFactor * easeOut(value: swipePosition,
                                                             startValue: 0,
                                                             endValue: item.view.bounds.width,
                                                             asymptote: item.view.bounds.width / 4)
            }

            layoutActions(inFullOpenArea: isFullOpenArea)
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

    func swipe(x: CGFloat) {
        if swipeIsFinished {
            originSwipePosition = swipePosition
        }
        swipePosition = originSwipePosition + x * directionFactor;
        swipeIsFinished = false
    }

    func swipeFinished(withXVelocity velocity: CGFloat) {
        guard !isFullOpenArea else {
            performFinishAnimation(toValue: -item.view.bounds.width)

            return
        }

        let maxOffsetForCompletion: CGFloat = item.view.bounds.width * kCompletionOffsetFactor
        let newVisibleActionsWidth: CGFloat
        let isSwipeToOpenActions = (direction == .leftToRight && velocity <= 0) || (direction == .rightToLeft && velocity >= 0)
        if isSwipeToOpenActions {
            if swipePosition < -maxOffsetForCompletion {
                newVisibleActionsWidth = -maxActionsVisibleWidth
            } else {
                newVisibleActionsWidth = 0
            }
        } else {
            if -maxActionsVisibleWidth - swipePosition < -maxOffsetForCompletion {
                newVisibleActionsWidth = 0
            } else {
                newVisibleActionsWidth = -maxActionsVisibleWidth
            }
        }

        performFinishAnimation(toValue: newVisibleActionsWidth)

        swipeIsFinished = true
    }

    func closeActions() {
        performFinishAnimation(toValue: 0) {
            self.removeButtonsFromCell()
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
        guard let containerView = containerView,
            (cellTranslationX <= 0 && direction == .leftToRight) ||
                (cellTranslationX >= 0 && direction == .rightToLeft) else {
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
