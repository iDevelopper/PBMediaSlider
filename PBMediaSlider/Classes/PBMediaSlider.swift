//
//  PBMediaSlider.swift
//  PBMediaSlider
//
//  Created by Patrick BODET on 28/01/2024.
//

import Foundation
import UIKit

@objc public enum PBMediaSliderStyle : Int {
    
    /**
     A control for selecting a single value from a continuous range of values.
     */
    case slider
    
    /**
     A control for selecting a single value from a continuous range of values, that depicts the progress of a task over time..
     */
    case progress
        
    /**
     Default style: slider (i.e. for Volume Slider).
     */
    public static let `default`: PBMediaSliderStyle = {
        return .slider
    }()
}

extension PBMediaSliderStyle
{
    /**
     An array of human readable strings for the slider view styles.
     */
    public static let strings = ["slider", "progress"]
    
    private func string() -> NSString {
        return PBMediaSliderStyle.strings[self.rawValue] as NSString
    }
    
    /**
     Return an human readable description for the slider view style.
     */
    public var description: NSString {
        get {
            return string()
        }
    }
}


/**
 PBMediaSlider is a small Swift Package aiming to recreate volume and track sliders found in Apple Music on iOS 16 and later.
 PBMediaSlider maintains an API similar to built-in UISlider. It has the same properties, like value and isContinuous. Progress observation is done the same way, by adding a target and an action:

 sliderControl.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
 
 Alternatively, you can subscribe to valuePublisher publisher to receive value updates:

 var cancellablePublisher: AnyCancellable!
 ...
 self.cancellablePublisher = slider.publisher(for: .valueChanged).sink { slider in
     if let slider = slider as? PBMediaSlider {
         print("slider value: \(slider.value)")
     }
 }
 */
@objc public class PBMediaSlider: UIControl {

    
    // MARK: - Public Properties

    /**
     The slider view style. Default is slider.
     */
    @objc public var style: PBMediaSliderStyle = .slider {
        didSet {
            if style == .progress {
                self.setupElapsedTimeLabel()
                self.setupHighlightedElapsedLabel()
                self.setupRemainingTimeLabel()
                self.setupHighlightedRemainingLabel()
                
                self.elapsedTimeLabelObserver = elapsedTimeLabel.observe(\.text) { [weak self] (label, observedChange) in
                    self?.highlightedElapsedTimeLabel?.text = label.text
                }
                self.remainingTimeLabelObserver = remainingTimeLabel.observe(\.text) { [weak self] (label, observedChange) in
                    self?.highlightedRemainingTimeLabel?.text = label.text
                }
                
                NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] notification in
                    if self?.style == .progress {
                        self?.setupElapsedTimeLabel()
                        self?.setupHighlightedElapsedLabel()
                        self?.setupRemainingTimeLabel()
                        self?.setupHighlightedRemainingLabel()
                    }
                }
            }
            self.setNeedsUpdateConstraints()
            self.updateConstraintsIfNeeded()
        }
    }

    /**
     The intrinsic slider height.
     
     The height of the slider is doubled during tracking.
     */
    @objc public var sliderIntrinsicHeight: CGFloat = 7.0
    
    /**
     The widening factor of the control when tracking. If you change the value of this property and it is less than 1.0, it is adjusted to 1.0 (no widening).
     */
    @objc public var wideningFactor: CGFloat = 1.04 {
        didSet {
            _wideningFactor = max(wideningFactor, 1.0)
            _wideningFactor = 1.0 + ((_wideningFactor - 1.0) / 2)
        }
    }
    private var _wideningFactor: CGFloat = 1.02

    /**
     The slider’s current value.
     
     Use this property to get and set the slider’s current value. To render an animated transition from the current value to the new value, use the setValue:animated: method instead.
     If you try to set a value that’s below the minimum or above the maximum, the minimum or maximum value is set instead. The default value of this property is 0.0.
     */
    @objc public var value: Float {
        set {
            self.currentValue = self._getValueFromValue(newValue)
            if !self.isTracking {
                self.progress = self._getProgressFromValue(self.value)
                self.trackView?.progress = self.progress
            }
            if let elapsedTimeLabel = self.elapsedTimeLabel {
                let elapsedTime = Self._secondsToHoursMinutesSecondsStr(seconds: self.value)
                elapsedTimeLabel.text = elapsedTime
                if let highlightedElapsedTimeLabel = self.highlightedElapsedTimeLabel {
                    highlightedElapsedTimeLabel.text = elapsedTimeLabel.text
                }
            }
            if let remainingTimeLabel = self.remainingTimeLabel {
                let remainingTime = "-" + Self._secondsToHoursMinutesSecondsStr(seconds: self.maximumValue - self.value)
                remainingTimeLabel.text = remainingTime
                if let highlightedRemainingTimeLabel = self.highlightedRemainingTimeLabel {
                    highlightedRemainingTimeLabel.text = remainingTimeLabel.text
                }
            }
        }
        get {
            return self.currentValue
        }
    }
        
    /**
     The slider’s current progress.

     Use this property to get the slider’s current progress. To change this value ot to render an animated transition from the current progress to the new progress, use the setProgress:animated: method.
     */
    @objc public private(set) var progress: CGFloat = 0.0 {
        didSet {
            self.trackView.progress = progress
        }
    }

    /**
     The minimum value of the slider.
     
     Use this property to set the value that the leading end of the slider represents. If you change the value of this property, and the current value of the slider is below the new minimum, the slider adjusts the value property to match the new minimum. If you set the minimum value to a value larger than the maximum, the slider updates the maximum value to equal the minimum.
     The default value of this property is 0.0.
     */
    @objc public var minimumValue: Float = 0.0 {
        didSet {
            if self.value < minimumValue {
                self.value = minimumValue
            }
            if minimumValue > self.maximumValue {
                self.maximumValue = minimumValue
            }
            self.inRange = minimumValue...self.maximumValue
        }
    }
    
    /**
     The maximum value of the slider.
     
     Use this property to set the value that the trailing end of the slider represents. If you change the value of this property, and the current value of the slider is above the new maximum, the slider adjusts the value property to match the new maximum. If you set the maximum value to a value smaller than the minimum, the slider updates the minimum value to equal the maximum.
     The default value of this property is 1.0.
     */
    @objc public var maximumValue: Float = 1.0 {
        didSet {
            if self.value > maximumValue {
                self.value = maximumValue
            }
            if maximumValue < self.minimumValue {
                self.minimumValue = maximumValue
            }
            self.inRange = self.minimumValue...maximumValue
        }
    }
        
    /**
     A Boolean value indicating whether changes in the slider’s value generate continuous update events.
     
     If true, the slider triggers the associated target’s action method repeatedly, as the user tracks it. If false, the slider triggers the associated action method just once, when the user releases the slider’s control to set the final value.
     The default value of this property is true.
     */
    @objc public var isContinuous: Bool = true
    
    /**
     A Boolean value indicating whether the control is in the enabled state.
     */
    @objc public override var isEnabled: Bool {
        didSet {
            self.alpha = isEnabled ? 1.0 : 0.5
            self.updateColors()
        }
    }
        
    /**
     The visual effect applied to the `PBMediaSlider` elements.
     .
     Defaults to `UIVibrancyEffect.UIVibrancyEffectStyle.fill` over `UIBlurEffect.Style.systemMaterial`  for labels.
     Defaults to `UIVibrancyEffect.UIVibrancyEffectStyle.label` over `UIBlurEffect.Style.systemMaterial`  for images.
     
     The effect can be modified as follows:
     slider.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial), style: .fill)
     
     If nil, no effect is applied.
     */
    @objc public var effect: UIVisualEffect! {
        didSet {
            self.slider.effectView?.effect = effect
            self.slider.effect = effect
            self.minimumValueImageView?.effectView?.effect = effect
            self.minimumValueImageView?.effect = effect
            self.maximumValueImageView?.effectView?.effect = effect
            self.maximumValueImageView?.effect = effect
            self.elapsedTimeLabel?.effectView?.effect = effect
            self.elapsedTimeLabel?.effect = effect
            self.remainingTimeLabel?.effectView?.effect = effect
            self.remainingTimeLabel?.effect = effect
        }
    }
    
    /**
     The visual effect applied to the `slider`.
     */
    @objc public var sliderEffect: UIVisualEffect! {
        didSet {
            self.slider.effectView?.effect = sliderEffect
            self.slider.effect = sliderEffect
        }
    }

    /**
     The visual effect applied to  `minimumValueImageView` and `maximumValueImageView`.
     */
    @objc public var imagesEffect: UIVisualEffect! {
        didSet {
            self.minimumValueImageView?.effectView?.effect = imagesEffect
            self.minimumValueImageView?.effect = imagesEffect
            self.maximumValueImageView?.effectView?.effect = imagesEffect
            self.maximumValueImageView?.effect = imagesEffect
        }
    }

    /**
     The visual effect applied to  `elapsedTimeLabel` and `remainingTimeLabel`.
     */
    @objc public var labelsEffect: UIVisualEffect! {
        didSet {
            self.elapsedTimeLabel?.effectView?.effect = labelsEffect
            self.elapsedTimeLabel?.effect = labelsEffect
            self.remainingTimeLabel?.effectView?.effect = labelsEffect
            self.remainingTimeLabel?.effect = labelsEffect
        }
    }

    /**
     The default color for the part of the slider that is not filled.
     */
    @objc public var emptyColor: UIColor!
    {
        set {
            _emptyColor = newValue
            self.updateColors()
        }
        get {
            return _emptyColor != nil ? _emptyColor : UIColor.systemFill
        }
    }
    private var _emptyColor: UIColor! = UIColor.systemFill

    /**
     The default color for the part of the slider that is filled.
     */
    @objc public var fillColor: UIColor!
    {
        set {
            _fillColor = newValue
            self.updateColors()
        }
        get {
            return _fillColor != nil ? _fillColor : self.tintColor
        }
    }
    private var _fillColor: UIColor! = UIColor.label.withAlphaComponent(0.5)

    /**
     The default color for the part of the slider that is filled when tracking.
     */
    @objc public var activeFillColor: UIColor!
    {
        set {
            _activeFillColor = newValue
            self.updateColors()
        }
        get {
            return _activeFillColor != nil ? _activeFillColor : self.tintColor
        }
    }
    private var _activeFillColor: UIColor! = UIColor.label

    /**
     The image that represents the slider’s minimum value.
     
     The default value of this property is nil.
     */
    @objc public var minimumValueImage: UIImage? {
        didSet {
            minimumValueImage = minimumValueImage?.withRenderingMode(.alwaysTemplate).applyingSymbolConfiguration(self.smallImageConfiguration)
            self.setupMinimumValueImageView()
        }
    }

    /**
     The image that represents the slider’s maximum value.
     
     The default value of this property is nil.
     */
    @objc public var maximumValueImage: UIImage? {
        didSet {
            maximumValueImage = maximumValueImage?.withRenderingMode(.alwaysTemplate).applyingSymbolConfiguration(self.smallImageConfiguration)
            self.setupMaximumValueImageView()
        }
    }
    
    /**
     The elapsed time label of the progress control (read-only, but its properties can be changed).
     */
    @objc public private(set) var elapsedTimeLabel: _PBMediaSliderTimeLabel!
    
    /**
     The remaining time label of the progress control (read-only, but its properties can be changed).
     */
    @objc public private(set) var remainingTimeLabel: _PBMediaSliderTimeLabel!
    /**
     Controls whether interaction with the popup generates haptic feedback to the user.
    
     Defaults to `true`.

     */
    @objc public var allowHapticFeedbackGeneration: Bool = true

    /**
     The `UIImpactFeedbackGenerator.FeedbackStyle` used for haptic feedback when the slider reaches either end of its track.
     
      - Requires: iOS 10.0 or later
     
      - Note: Defaults to `.light` if not set
     */
    @available(iOS 10.0, *) public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        get {
            guard let _feedbackStyle = _feedbackStyle,
                let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: _feedbackStyle) else { return .light }
            return style
        }
        set(newValue) {
            _feedbackStyle = newValue.rawValue
        }
    }

    
    // MARK: - Private Properties
    
    private var isActive: Bool = false {
        didSet {
            self.trackView?.maskLayer.backgroundColor = isActive ? self.activeFillColor : self.fillColor
            self.minimumValueImageView?.alpha = isActive ? 0.0 : 1.0
            self.minimumValueHighlightedImageView?.alpha = isActive ? 1.0 : 0.0
            self.maximumValueImageView?.alpha = isActive ? 0.0 : 1.0
            self.maximumValueHighlightedImageView?.alpha = isActive ? 1.0 : 0.0
            self.elapsedTimeLabel?.alpha = isActive ? 0.0 : 1.0
            self.highlightedElapsedTimeLabel?.alpha = isActive ? 1.0 : 0.0
            self.remainingTimeLabel?.alpha = isActive ? 0.0 : 1.0
            self.highlightedRemainingTimeLabel?.alpha = isActive ? 1.0 : 0.0
            self.setNeedsUpdateConstraints()
            self.updateConstraintsIfNeeded()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    private var currentValue: Float = 0.0

    private var inRange: ClosedRange<Float>! = 0.0...1.0
    
    private var slider: _PBMediaSliderView!

    private var sliderViewCenterConstraint: NSLayoutConstraint!
    private var sliderViewLeadingConstraint: NSLayoutConstraint!
    private var sliderViewTrailingConstraint: NSLayoutConstraint!
    private var sliderViewHeightConstraint: NSLayoutConstraint!

    private var trackView: _PBMediaSliderTrackView!

    private var minimumValueImageView: _PBMediaSliderImageView!
    private var minimumValueHighlightedImageView: _PBMediaSliderImageView!

    private var minimumValueImageViewLeadingConstraint: NSLayoutConstraint!

    private var maximumValueImageView: _PBMediaSliderImageView!
    private var maximumValueHighlightedImageView: _PBMediaSliderImageView!

    private var maximumValueImageViewTrailingConstraint: NSLayoutConstraint!

    private var labelsTopMargin: CGFloat = 4.0

    private var highlightedElapsedTimeLabel: _PBMediaSliderTimeLabel!
    private var elapsedTimeLabelObserver: NSKeyValueObservation?

    private var highlightedRemainingTimeLabel: _PBMediaSliderTimeLabel!
    private var remainingTimeLabelObserver: NSKeyValueObservation?

    private var smallImageConfiguration: UIImage.SymbolConfiguration {
        let scaleConfig = UIImage.SymbolConfiguration(scale: .small)
        let weightConfig = UIImage.SymbolConfiguration(weight: .semibold)
        let config = scaleConfig.applying(weightConfig)
        return config
    }
    
    private var largeImageConfiguration: UIImage.SymbolConfiguration {
        let scaleConfig = UIImage.SymbolConfiguration(scale: .large)
        let weightConfig = UIImage.SymbolConfiguration(weight: .semibold)
        let config = scaleConfig.applying(weightConfig)
        return config
    }

    // gross workaround for not being able to use @available on stored properties, from https://www.klundberg.com/blog/Swift-2-and-@available-properties/
    private var _minMaxFeedbackGenerator: AnyObject?
    @available(iOS 10.0, *) private var minMaxFeedbackGenerator: UIImpactFeedbackGenerator? {
        get {
            return _minMaxFeedbackGenerator as? UIImpactFeedbackGenerator
        }
        set(newValue) {
            _minMaxFeedbackGenerator = newValue
        }
    }
    
    private var _feedbackStyle: Int?
    
    
    // MARK: - Initialization

    convenience public init(frame: CGRect, value: Float = 0.0, inRange: ClosedRange<Float> = 0.0...1.0, activeFillColor: UIColor!, fillColor: UIColor!, emptyColor: UIColor!)
    {
        self.init(frame: frame)
        
        self.minimumValue = inRange.lowerBound
        self.maximumValue = inRange.upperBound
        self.inRange = inRange
        
        self.commonInit()
        
        self.emptyColor = emptyColor
        self.fillColor = fillColor
        self.activeFillColor = activeFillColor
        
        self.value = value
    }
    
    convenience public init(frame: CGRect, value: Float = 0.0, minimumValue: Float = 0.0, maximumValue: Float = 1.0, activeFillColor: UIColor!, fillColor: UIColor!, emptyColor: UIColor!)
    {
        self.init(frame: frame)
        
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        
        self.commonInit()
        
        self.emptyColor = emptyColor
        self.fillColor = fillColor
        self.activeFillColor = activeFillColor
        
        self.value = value
    }
    
    convenience public init()
    {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 100, height: 30))
                
        self.commonInit()
        
        self.value = 0.0
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        self.commonInit()
        
        self.value = 0.0
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    // MARK: - Methods to override
    
    /**
     :nodoc:
     */
    public override func updateConstraints()
    {
        guard self.slider != nil else {
            super.updateConstraints()
            return
        }
        
        var constant: CGFloat
        
        // Slider Center
        if self.style == .slider {
            constant = self.isActive ? 0.0 : 0.0
        }
        else {
            // .progress
            let labelHeight = self.elapsedTimeLabel.intrinsicContentSize.height
            let height = sliderIntrinsicHeight + labelHeight + labelsTopMargin
            constant = -(height - sliderIntrinsicHeight) / 2
        }
        if let sliderViewCenterConstraint = self.sliderViewCenterConstraint {
            sliderViewCenterConstraint.constant = constant
        }
        else {
            self.sliderViewCenterConstraint = self.slider.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: constant)
            self.sliderViewCenterConstraint.isActive = true
        }

        // Slider Height
        constant = self.isActive ? self.sliderIntrinsicHeight * 2 : self.sliderIntrinsicHeight
        
        if let sliderViewHeightConstraint = self.sliderViewHeightConstraint {
            sliderViewHeightConstraint.constant = constant
        }
        else {
            self.sliderViewHeightConstraint = self.slider.heightAnchor.constraint(equalToConstant: constant)
            self.sliderViewHeightConstraint.isActive = true
        }
                
        // Slider Leading
        if let image = self.minimumValueImage {
            constant = image.size.width + 8.0
        }
        else {
            constant = 0.0
        }
        if self.isActive {
            constant -= (self.bounds.width * _wideningFactor - self.bounds.width)
        }
        if let sliderViewLeadingConstraint = self.sliderViewLeadingConstraint {
            sliderViewLeadingConstraint.constant = constant
        }
        else {
            self.sliderViewLeadingConstraint = self.slider.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: constant)
            self.sliderViewLeadingConstraint.isActive = true
        }
        
        // Slider Trailing
        if let image = self.maximumValueImage {
            constant = -(image.size.width + 8.0)
            
        }
        else {
            constant = 0.0
        }
        if self.isActive {
            constant += (self.bounds.width * _wideningFactor - self.bounds.width)
        }
        if let sliderViewTrailingConstraint = self.sliderViewTrailingConstraint {
            sliderViewTrailingConstraint.constant = constant
        }
        else {
            self.sliderViewTrailingConstraint = self.slider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: constant)
            self.sliderViewTrailingConstraint.isActive = true
        }
        
        // minimumValueImage leading
        constant = self.isActive ? -(self.bounds.width * _wideningFactor - self.bounds.width) : 0.0
        if let leadingConstraint = self.minimumValueImageViewLeadingConstraint {
            leadingConstraint.constant = constant
        }
        else {
            self.minimumValueImageViewLeadingConstraint = self.minimumValueImageView?.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: constant)
            self.minimumValueImageViewLeadingConstraint?.isActive = true
        }
        
        self.minimumValueImageView?.centerYAnchor.constraint(equalTo: self.slider.centerYAnchor, constant: 0).isActive = true

        // maximumValueImage trailing
        constant = self.isActive ? (self.bounds.width * _wideningFactor - self.bounds.width) : 0.0
        if let trailingConstraint = self.maximumValueImageViewTrailingConstraint {
            trailingConstraint.constant = constant
        }
        else {
            self.maximumValueImageViewTrailingConstraint = self.maximumValueImageView?.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: constant)
            self.maximumValueImageViewTrailingConstraint?.isActive = true
        }
        
        self.maximumValueImageView?.centerYAnchor.constraint(equalTo: self.slider.centerYAnchor, constant: 0).isActive = true

        // elapsedTimeLabel leading
        if let elapsedTimeLabel = self.elapsedTimeLabel,  elapsedTimeLabel.translatesAutoresizingMaskIntoConstraints == true {
            elapsedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
            elapsedTimeLabel.topAnchor.constraint(equalTo: self.slider.bottomAnchor, constant: labelsTopMargin).isActive = true
            elapsedTimeLabel.leadingAnchor.constraint(equalTo: self.slider.leadingAnchor, constant: 0.0).isActive = true
        }
        
        // remainingTimeLabel trailing
        if let remainingTimeLabel = self.remainingTimeLabel,  remainingTimeLabel.translatesAutoresizingMaskIntoConstraints == true {
            remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
            remainingTimeLabel.topAnchor.constraint(equalTo: self.slider.bottomAnchor, constant: labelsTopMargin).isActive = true
            remainingTimeLabel.trailingAnchor.constraint(equalTo: self.slider.trailingAnchor, constant: 0.0).isActive = true
        }
        
        if let effectView = slider.effectView {
            effectView.setNeedsLayout()
            effectView.layoutIfNeeded()
        }

        super.updateConstraints()
    }
    
    /**
     :nodoc:
     */
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        if self.isTracking { return }
        
        guard let trackView = self.trackView,
              let slider = self.slider,
              let effectView = slider.effectView
        else {
            return
        }
        
        let height = slider.bounds.height
        
        effectView.layer.cornerRadius = height / 2
        slider.layer.cornerRadius = height / 2
        trackView.layer.cornerRadius = height / 2

        self.progress = self._getProgressFromValue(self.value)
        
        trackView.frame = effectView.frame
        trackView.progress = self.progress
    }
    
    /**
     :nodoc:
     */
    public override func tintColorDidChange()
    {
        super.tintColorDidChange()
        
        self.updateColors()
    }
    
    /**
     :nodoc:
     */
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.updateColors()
    }
    
    /**
     :nodoc:
     */
    public override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?)
    {
        super.sendAction(action, to: target, for: event)
    }
    
    /**
     :nodoc:
     */
    public override func sendActions(for controlEvents: UIControl.Event)
    {
        if controlEvents == .valueChanged {
            super.sendActions(for: controlEvents)
        }
    }
    
    // MARK: - Public Methods
    
    @objc public func setValue(_ value: Float, animated: Bool)
    {
        let block = {
            self.progress = self._getProgressFromValue(value)
            self.value = value
        }
        if animated {
            UIView.animate(withDuration: 0.15) {
                block()
            }
        }
        else {
            UIView.performWithoutAnimation(block)
        }
    }
    
    @objc public func setProgress(_ progress: CGFloat, animated: Bool)
    {
        let block = {
            let progress = max(min(progress, 1.0), 0.0)
            self.progress = progress
            self.value = self._getValueFromProgress(progress)
        }
        if animated {
            UIView.animate(withDuration: 0.15) {
                block()
            }
        }
        else {
            UIView.performWithoutAnimation(block)
        }
    }


    // MARK: - Private Methods
    
    private func commonInit()
    {
        self.setupSliderView()
        
        self.setupTrackView()
                
        self.configureContentSizeCategory()

        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
        
        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.updateColors()
            }
        }
    }
            
    private func updateColors()
    {
        self.slider?.backgroundColor = self.emptyColor
        self.trackView?.maskLayer.backgroundColor = isActive ? self.activeFillColor : self.fillColor
        self.minimumValueImageView?.tintColor = isActive ? self.activeFillColor : self.fillColor
        self.minimumValueHighlightedImageView?.tintColor = self.activeFillColor
        self.maximumValueImageView?.tintColor = isActive ? self.activeFillColor : self.fillColor
        self.maximumValueHighlightedImageView?.tintColor = self.activeFillColor
        self.elapsedTimeLabel?.textColor = isActive ? self.activeFillColor : self.fillColor
        self.highlightedElapsedTimeLabel?.textColor = self.activeFillColor
        self.remainingTimeLabel?.textColor = isActive ? self.activeFillColor : self.fillColor
        self.highlightedRemainingTimeLabel?.textColor = self.activeFillColor
        
        self.updateEffects()
    }
    
    private func updateEffects()
    {
        self.slider.effectView?.effect = isEnabled ? _emptyColor != nil ? self.slider.effect : nil : nil
        self.minimumValueImageView?.effectView?.effect = isEnabled ? _fillColor != nil ? self.minimumValueImageView?.effect : nil : nil
        self.maximumValueImageView?.effectView?.effect = isEnabled ? _fillColor != nil ? self.maximumValueImageView?.effect : nil : nil
        self.elapsedTimeLabel?.effectView?.effect = isEnabled ? _fillColor != nil ? self.elapsedTimeLabel?.effect : nil : nil
        self.remainingTimeLabel?.effectView?.effect = isEnabled ? _fillColor != nil ? self.remainingTimeLabel?.effect : nil : nil
    }
    
    private func configureContentSizeCategory()
    {
        if #available(iOS 15.0, *) {
            self.minimumContentSizeCategory = .small
            self.maximumContentSizeCategory = .extraSmall
        }
    }
    
    private func applyVibrancyTo(_ view: UIView, withStyle style: UIVibrancyEffectStyle = .fill) -> UIVisualEffectView
    {
        let vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemMaterial), style: style))
        vibrancyEffectView.isUserInteractionEnabled = false
        vibrancyEffectView.layer.cornerCurve = .continuous
                
        self.addSubview(vibrancyEffectView)
        vibrancyEffectView.contentView.addSubview(view)
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        vibrancyEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        vibrancyEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        vibrancyEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        return vibrancyEffectView
    }
    
    private func setupSliderView()
    {
        self.slider = _PBMediaSliderView()
        slider.isUserInteractionEnabled = false
        slider.backgroundColor = self.emptyColor
        slider.layer.cornerCurve = .continuous
        slider.translatesAutoresizingMaskIntoConstraints = false

        let vibrancyEffectView = self.applyVibrancyTo(slider)
        slider.effectView = vibrancyEffectView
    }
    
    private func setupTrackView()
    {
        self.trackView = _PBMediaSliderTrackView()
        trackView.isUserInteractionEnabled = false
        trackView.clipsToBounds = true
        trackView.layer.masksToBounds = true
        trackView.backgroundColor = .clear
        trackView.maskLayer.backgroundColor = self.fillColor
        trackView.layer.cornerCurve = .continuous
        
        self.addSubview(trackView)
    }
    
    private func setupMinimumValueImageView()
    {
        self.minimumValueImageView = _PBMediaSliderImageView(image: minimumValueImage)
        minimumValueImageView.isUserInteractionEnabled = false
        minimumValueImageView.tintColor = self.fillColor
        self.addSubview(minimumValueImageView)
        minimumValueImageView.translatesAutoresizingMaskIntoConstraints = false
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
        
        let vibrancyEffectView = self.applyVibrancyTo(minimumValueImageView, withStyle: .label)
        minimumValueImageView.effectView = vibrancyEffectView
        if let effect = self.imagesEffect {
            minimumValueImageView.effectView?.effect = effect
            minimumValueImageView.effect = effect
        }
        
        self.minimumValueHighlightedImageView = _PBMediaSliderImageView(image: minimumValueImage)
        minimumValueHighlightedImageView.isUserInteractionEnabled = false
        minimumValueHighlightedImageView.tintColor = self.activeFillColor
        minimumValueHighlightedImageView.alpha = 0.0
        
        self.addSubview(minimumValueHighlightedImageView)
        
        minimumValueHighlightedImageView.translatesAutoresizingMaskIntoConstraints = false
        minimumValueHighlightedImageView.topAnchor.constraint(equalTo: minimumValueImageView.topAnchor).isActive = true
        minimumValueHighlightedImageView.leadingAnchor.constraint(equalTo: minimumValueImageView.leadingAnchor).isActive = true
        minimumValueHighlightedImageView.trailingAnchor.constraint(equalTo: minimumValueImageView.trailingAnchor).isActive = true
        minimumValueHighlightedImageView.bottomAnchor.constraint(equalTo: minimumValueImageView.bottomAnchor).isActive = true
    }
    
    private func setupMaximumValueImageView()
    {
        self.maximumValueImageView = _PBMediaSliderImageView(image: maximumValueImage)
        maximumValueImageView.isUserInteractionEnabled = false
        maximumValueImageView.tintColor = self.fillColor
        self.addSubview(maximumValueImageView)
        maximumValueImageView.translatesAutoresizingMaskIntoConstraints = false
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
        
        let vibrancyEffectView = self.applyVibrancyTo(maximumValueImageView, withStyle: .label)
        maximumValueImageView.effectView = vibrancyEffectView
        if let effect = self.imagesEffect {
            maximumValueImageView.effectView?.effect = effect
            maximumValueImageView.effect = effect
        }

        self.maximumValueHighlightedImageView = _PBMediaSliderImageView(image: maximumValueImage)
        maximumValueHighlightedImageView.isUserInteractionEnabled = false
        maximumValueHighlightedImageView.tintColor = self.activeFillColor
        maximumValueHighlightedImageView.alpha = 0.0
        
        self.addSubview(maximumValueHighlightedImageView)
        
        maximumValueHighlightedImageView.translatesAutoresizingMaskIntoConstraints = false
        maximumValueHighlightedImageView.topAnchor.constraint(equalTo: maximumValueImageView.topAnchor).isActive = true
        maximumValueHighlightedImageView.leadingAnchor.constraint(equalTo: maximumValueImageView.leadingAnchor).isActive = true
        maximumValueHighlightedImageView.trailingAnchor.constraint(equalTo: maximumValueImageView.trailingAnchor).isActive = true
        maximumValueHighlightedImageView.bottomAnchor.constraint(equalTo: maximumValueImageView.bottomAnchor).isActive = true
    }
    
    private func setupElapsedTimeLabel()
    {
        if self.elapsedTimeLabel == nil {
            self.elapsedTimeLabel = _PBMediaSliderTimeLabel()
            elapsedTimeLabel.isUserInteractionEnabled = false
            elapsedTimeLabel.isAccessibilityElement = true
            elapsedTimeLabel.adjustsFontForContentSizeCategory = true
            elapsedTimeLabel.text = "0:00"
            elapsedTimeLabel.textColor = self.fillColor
            elapsedTimeLabel.textAlignment = .left

            let vibrancyEffectView = self.applyVibrancyTo(elapsedTimeLabel)
            elapsedTimeLabel.effectView = vibrancyEffectView
            if let effect = self.labelsEffect {
                elapsedTimeLabel.effectView?.effect = effect
                elapsedTimeLabel.effect = effect
            }
        }
        elapsedTimeLabel.font = UIFont.preferredMonospacedFont(for: .headline, weight: .medium)
        
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
    }
    
    private func setupHighlightedElapsedLabel()
    {
        if self.highlightedElapsedTimeLabel == nil {
            self.highlightedElapsedTimeLabel = _PBMediaSliderTimeLabel()
            highlightedElapsedTimeLabel.isUserInteractionEnabled = false
            highlightedElapsedTimeLabel.isAccessibilityElement = true
            highlightedElapsedTimeLabel.adjustsFontForContentSizeCategory = true
            highlightedElapsedTimeLabel.text = "0:00"
            highlightedElapsedTimeLabel.textColor = self.activeFillColor
            highlightedElapsedTimeLabel.textAlignment = .left
            highlightedElapsedTimeLabel.alpha = 0.0
            
            self.addSubview(highlightedElapsedTimeLabel)
            
            highlightedElapsedTimeLabel.translatesAutoresizingMaskIntoConstraints = false
            highlightedElapsedTimeLabel.topAnchor.constraint(equalTo: elapsedTimeLabel.topAnchor).isActive = true
            highlightedElapsedTimeLabel.leadingAnchor.constraint(equalTo: elapsedTimeLabel.leadingAnchor).isActive = true
            highlightedElapsedTimeLabel.trailingAnchor.constraint(equalTo: elapsedTimeLabel.trailingAnchor).isActive = true
            highlightedElapsedTimeLabel.bottomAnchor.constraint(equalTo: elapsedTimeLabel.bottomAnchor).isActive = true
        }
        highlightedElapsedTimeLabel.font = elapsedTimeLabel.font
    }

    private func setupRemainingTimeLabel()
    {
        if self.remainingTimeLabel == nil {
            self.remainingTimeLabel = _PBMediaSliderTimeLabel()
            remainingTimeLabel.isUserInteractionEnabled = false
            remainingTimeLabel.isAccessibilityElement = true
            remainingTimeLabel.adjustsFontForContentSizeCategory = true
            remainingTimeLabel.text = "-0:00"
            remainingTimeLabel.textColor = self.fillColor
            remainingTimeLabel.textAlignment = .right

            let vibrancyEffectView = self.applyVibrancyTo(remainingTimeLabel)
            remainingTimeLabel.effectView = vibrancyEffectView
            if let effect = self.labelsEffect {
                remainingTimeLabel.effectView?.effect = effect
                remainingTimeLabel.effect = effect
            }
        }
        remainingTimeLabel.font = UIFont.preferredMonospacedFont(for: .headline, weight: .medium)
        
        self.setNeedsUpdateConstraints()
        self.updateConstraintsIfNeeded()
    }

    private func setupHighlightedRemainingLabel()
    {
        if self.highlightedRemainingTimeLabel == nil {
            self.highlightedRemainingTimeLabel = _PBMediaSliderTimeLabel()
            highlightedRemainingTimeLabel.isUserInteractionEnabled = false
            highlightedRemainingTimeLabel.isAccessibilityElement = true
            highlightedRemainingTimeLabel.adjustsFontForContentSizeCategory = true
            highlightedRemainingTimeLabel.text = "-0:00"
            highlightedElapsedTimeLabel.textColor = self.activeFillColor
            highlightedRemainingTimeLabel.textAlignment = .right
            highlightedRemainingTimeLabel.alpha = 0.0
            
            self.addSubview(highlightedRemainingTimeLabel)
            
            highlightedRemainingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
            highlightedRemainingTimeLabel.topAnchor.constraint(equalTo: remainingTimeLabel.topAnchor).isActive = true
            highlightedRemainingTimeLabel.leadingAnchor.constraint(equalTo: remainingTimeLabel.leadingAnchor).isActive = true
            highlightedRemainingTimeLabel.trailingAnchor.constraint(equalTo: remainingTimeLabel.trailingAnchor).isActive = true
            highlightedRemainingTimeLabel.bottomAnchor.constraint(equalTo: remainingTimeLabel.bottomAnchor).isActive = true
        }
        highlightedRemainingTimeLabel.font = remainingTimeLabel.font
    }

    private func animateMinimumValueImage()
    {
        if let minimumValueHighlightedImageView = self.minimumValueHighlightedImageView {
            if #available(iOS 17.0, *) {
                minimumValueHighlightedImageView.addSymbolEffect(.bounce.byLayer, options: .nonRepeating, animated: true)
            } else {
                UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                    minimumValueHighlightedImageView.frame = minimumValueHighlightedImageView.frame.insetBy(dx: 4.0, dy: 3.0)
                })
            }
        }
    }

    private func animateMaximumValueImage()
    {
        if let maximumValueHighlightedImageView = self.maximumValueHighlightedImageView {
            if #available(iOS 17.0, *) {
                maximumValueHighlightedImageView.addSymbolEffect(.bounce.byLayer, options: .nonRepeating, animated: true)
            } else {
                UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: {
                    maximumValueHighlightedImageView.frame = maximumValueHighlightedImageView.frame.insetBy(dx: 4.0, dy: 3.0)
                })
            }
        }
    }

    // MARK: - Progress & Value Calculation Methods

    private func _getValueFromValue(_ value: Float) -> Float {
        let value = max(min(value, inRange.upperBound), inRange.lowerBound)
        return value
    }
    
    private func _getValueFromProgress(_ progress: CGFloat) -> Float
    {
        let range = inRange.upperBound - inRange.lowerBound
        let value = ((Float(progress) * range) + inRange.lowerBound)
        return max(min(value, inRange.upperBound), inRange.lowerBound)
    }
    
    private func _getProgressFromValue(_ value: Float) -> CGFloat
    {
        let range = inRange.upperBound - inRange.lowerBound
        if range == 0.0 { return 0.0 }
        let correctedValue = value - inRange.lowerBound
        return CGFloat(correctedValue / range)
    }
    
    private func _getValueFromTranslation(_ translation: CGFloat) -> Float
    {
        let range = inRange.upperBound - inRange.lowerBound
        return Float(translation / self.slider.bounds.width) * range
    }

    // MARK: - Class methods for converting time to string
    
    fileprivate class func _secondsToHoursMinutesSeconds(seconds : Int) -> (Int, Int, Int)
    {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    fileprivate class func _secondsToHoursMinutesSecondsStr(seconds: Float) -> String
    {
        let seconds = Int(seconds)
        let (hh, mm, ss) = _secondsToHoursMinutesSeconds(seconds: abs(seconds))
        var str = hh > 0 ? String(format: "%02d:", hh) : ""
        str = str + String(format: "%02d:", mm)
        str = str + String(format: "%02d", ss)
        if str.hasPrefix("0") {
            str = String(str.dropFirst())
        }
        if seconds < 0 {
            str = "-" + str
        }
        return str
    }
    

    // MARK: - Tracking Methods

    /**
     :nodoc:
     */
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        super.beginTracking(touch, with: event)
        
        self.setState(true)
        if self.allowHapticFeedbackGeneration {
            self.minMaxFeedbackGenerator = UIImpactFeedbackGenerator(style: feedbackStyle)
            self.minMaxFeedbackGenerator?.prepare()
        }
        return true
    }
    
    /**
     :nodoc:
     */
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        super.continueTracking(touch, with: event)
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
        let translation = layoutDirection == .leftToRight ? (location.x - previousLocation.x) : (previousLocation.x - location.x)
        let value = self.value + self._getValueFromTranslation(translation)
        if allowHapticFeedbackGeneration {
            if (value <= self.value && self.value > self.minimumValue && value <= self.minimumValue)
            {
                self.minMaxFeedbackGenerator?.impactOccurred()
                self.minMaxFeedbackGenerator?.prepare()
                self.animateMinimumValueImage()
            }
            if (value >= self.value && self.value < self.maximumValue && value >= self.maximumValue)
            {
                self.minMaxFeedbackGenerator?.impactOccurred()
                self.minMaxFeedbackGenerator?.prepare()
                self.animateMaximumValueImage()
            }
        }
        let progress = self._getProgressFromValue(value)
        self.progress = progress
        self.value = value
        if self.isContinuous {
            sendActions(for: .valueChanged)
        }
        return true
    }
    
    /**
     :nodoc:
     */
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?)
    {
        if self.isTracking && !self.isContinuous {
            sendActions(for: .valueChanged)
        }
        super.endTracking(touch, with: event)
        
        _minMaxFeedbackGenerator = nil
        self.setState(false)
    }

    private func setState(_ active: Bool)
    {
        if active  {
            UIView.animate(withDuration: 0.25) {
                self.isActive = true
            }
        }
        else {
            if !self.isActive { return }
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: []) {
                self.isActive = false
            }
        }
    }
}

extension PBMediaSlider
{
    private class _PBMediaSliderView: UIView
    {
        var effectView: UIVisualEffectView? {
            didSet {
                self.effect = effectView?.effect
            }
        }
        
        var effect: UIVisualEffect?

        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
        }
    }

    private class _PBMediaSliderTrackView: UIView
    {
        var maskLayer: UIView!
        
        var progress: CGFloat! {
            didSet {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.clipsToBounds = true
            self.maskLayer = UIView()
            self.addSubview(maskLayer)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
        }
                
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.maskLayer.frame = self.bounds
            
            self.maskLayer.frame.size.width = self.bounds.size.width * self.progress
            if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                self.maskLayer.frame.origin.x = self.bounds.width - self.bounds.size.width * self.progress
            }
        }
    }
    
    /**
     :nodoc:
     */
    public class _PBMediaSliderTimeLabel: UILabel
    {
        internal var effectView: UIVisualEffectView? {
            didSet {
                self.effect = effectView?.effect
            }
        }
        
        internal var effect: UIVisualEffect?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override func tintColorDidChange() {
            super.tintColorDidChange()
        }
    }
    
    private class _PBMediaSliderImageView: UIImageView
    {
        var effectView: UIVisualEffectView? {
            didSet {
                self.effect = effectView?.effect
            }
        }
        
        var effect: UIVisualEffect?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        public override init(image: UIImage?) {
            super.init(image: image)
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
        }
    }
}
