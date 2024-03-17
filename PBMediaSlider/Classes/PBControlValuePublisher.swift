//
//  PBControlValuePublisher.swift
//  PBMediaSlider
//
//  Created by Patrick BODET on 28/01/2024.
//
// https://www.avanderlee.com/swift/custom-combine-publisher/

import Foundation
import UIKit
import Combine

/// A custom subscription to capture UIControl target events.
final public class UIControlSubscription<SubscriberType: Subscriber, Control: UIControl>: Subscription where SubscriberType.Input == Control {
    private var subscriber: SubscriberType?
    private let control: Control

    init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        control.addTarget(self, action: #selector(eventHandler), for: event)
    }

    public func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    public func cancel() {
        subscriber = nil
    }

    @objc private func eventHandler() {
        _ = subscriber?.receive(control)
    }
}

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
public struct UIControlPublisher<Control: UIControl>: Publisher {

    public typealias Output = Control
    public typealias Failure = Never

    let control: Control
    let controlEvents: UIControl.Event

    init(control: Control, events: UIControl.Event) {
        self.control = control
        self.controlEvents = events
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == UIControlPublisher.Failure, S.Input == UIControlPublisher.Output {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
        subscriber.receive(subscription: subscription)
    }
}

/// Extending the `UIControl` types to be able to produce a `UIControl.Event` publisher.
public protocol CombineCompatible { }
extension PBMediaSlider: CombineCompatible { }
public extension CombineCompatible where Self: PBMediaSlider {
    /**
     A publisher that emits `UIControl.Event` when user interacts with the slider.
     A Combine alternative to adding action for `UIControl.Event`.
     */
    func publisher(for events: UIControl.Event) -> UIControlPublisher<UIControl> {
        return UIControlPublisher(control: self, events: events)
    }
}
