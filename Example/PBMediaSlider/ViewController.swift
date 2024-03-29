//
//  ViewController.swift
//  MusicSliderSwift
//
//  Created by Patrick BODET on 23/01/2024.
//

import UIKit
import Combine
import PBMediaSlider

class ViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.alwaysBounceVertical = false
            scrollView.alwaysBounceHorizontal = false
            scrollView.bounces = false
       }
    }
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    
    // "اضبط القيمة على"
    @IBOutlet weak var valueLabel: UILabel! {
        didSet {
            valueLabel.textColor = .label
            valueLabel.tag = 998
            valueLabel.adjustsFontForContentSizeCategory = true
            if #available(iOS 15.0, *) {
                valueLabel.maximumContentSizeCategory = .extraSmall
            }
        }
    }
    @IBOutlet weak var valueButton: UIButton! {
        didSet {
            valueButton.titleLabel?.adjustsFontForContentSizeCategory = true
            if #available(iOS 15.0, *) {
                valueButton.maximumContentSizeCategory = .accessibilityMedium
            }
            
            if #available(iOS 15.0, *) {
                var configuration = UIButton.Configuration.filled()
                configuration.cornerStyle = .capsule
                configuration.title = "0.50"
                configuration.baseForegroundColor = UIColor.label
                configuration.baseBackgroundColor = UIColor(dynamicProvider: { $0.userInterfaceStyle == .dark ? .black : .white })
                configuration.contentInsets = NSDirectionalEdgeInsets(top: 5.0, leading: 10.0, bottom: 5.0, trailing: 10.0)
                valueButton.configuration = configuration
            }
            else {
                valueButton.setTitle("0.50", for: .normal)
                valueButton.setTitleColor(.label, for: .normal)
                valueButton.backgroundColor = UIColor(dynamicProvider: { $0.userInterfaceStyle == .dark ? .black : .white })
                valueButton.layer.cornerRadius = 8
                valueButton.layer.cornerCurve = .continuous
                valueButton.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 10.0)
            }
        }
    }
    
    // "ممكّن"
    @IBOutlet weak var enabledLabel: UILabel! {
        didSet {
            enabledLabel.textColor = .label
            enabledLabel.tag = 998
            enabledLabel.adjustsFontForContentSizeCategory = true
            if #available(iOS 15.0, *) {
                enabledLabel.maximumContentSizeCategory = .small
            }
        }
    }
    
    @IBOutlet weak var enableSwitch: UISwitch!

    // "الوضع المظلم"
    @IBOutlet weak var modeLabel: UILabel! {
        didSet {
            modeLabel.textColor = .label
            modeLabel.tag = 998
            modeLabel.adjustsFontForContentSizeCategory = true
            if #available(iOS 15.0, *) {
                modeLabel.maximumContentSizeCategory = .small
            }
        }
    }
    @IBOutlet weak var modeSwitch: UISwitch! {
        didSet {
            modeSwitch.isOn = self.traitCollection.userInterfaceStyle == .dark
        }
    }
    
    var backgroundView: UIImageView!
    
    private let rtlKey = "isRtlDirection"
    
    var layoutDirection:UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute)
    }
    
    var slider1: PBMediaSlider!, slider2: PBMediaSlider!, slider3: PBMediaSlider!, slider5: PBMediaSlider!, slider4: PBMediaSlider!
    var valueLabel1: UILabel!, valueLabel2: UILabel!, valueLabel3: UILabel!, valueLabel4: UILabel!
    
    var cancellablePublisher4: AnyCancellable!

    var uislider: UISlider!
        
    var emptyColor: UIColor {
        return UIColor.systemFill
    }
    
    var fillColor: UIColor {
        return UIColor.label.withAlphaComponent(0.5)
    }
    
    var activeFillColor: UIColor {
        return UIColor.label
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if UserDefaults.standard.object(forKey: rtlKey) == nil {
            UserDefaults.standard.set(false, forKey: rtlKey)
            UserDefaults.standard.synchronize()
        }
        let rtlDirection = UserDefaults.standard.bool(forKey: rtlKey)
        UIView.appearance().semanticContentAttribute = rtlDirection ? .forceRightToLeft : .forceLeftToRight
        
        let rtlItem = UIBarButtonItem(title: rtlDirection ? "RTL" : "LTR", style: .plain, target: self, action: #selector(changeLayoutDirection(_ :)))
        self.navigationItem.rightBarButtonItem = rtlItem
        let colorsItem = UIBarButtonItem(image: UIImage(systemName: "circle.hexagongrid.fill")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(changeBackground(_:)))
        self.navigationItem.leftBarButtonItem = colorsItem

        self.containerView.backgroundColor = nil
        
        self.view.tintColor = UIColor.label
        self.navigationController?.navigationBar.tintColor = UIColor.label
        
        self.setupBackground()
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] notification in
            self?.updateLabelFonts()
        }
        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.updateLabelColors()
            }
        }
    }
    
    override func viewIsAppearing(_ animated: Bool)
    {
        super.viewIsAppearing(animated)
        
        self.setupViews()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        valueButton.layer.cornerRadius = valueButton.bounds.height / 2
        let containerHeight = self.uislider != nil ? self.uislider.frame.maxY : self.valueLabel4.frame.maxY
        let optionsHeight = self.modeSwitch.frame.maxY - self.valueLabel.frame.minY
        let totalHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        let scrollHeight = totalHeight - optionsHeight - view.safeAreaInsets.bottom
        
        if let heightConstraint = self.scrollViewHeightConstraint {
            heightConstraint.constant = scrollHeight
        }
        if let heightConstraint = self.containerViewHeightConstraint {
            heightConstraint.constant = max(containerHeight, scrollHeight)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.updateLabelColors()
    }

    // MARK: - Setup UI Methods
    
    private func setupBackground()
    {
        let image = UIImage(named: String(format: "Cover%02d", Int.random(in: 1...23)))
        
        self.view.backgroundColor = image?.averageColor
        
        self.updateLabelColors()
                
        self.backgroundView = UIImageView(image: image)
        backgroundView.contentMode = .scaleAspectFill

        self.containerView.insertSubview(backgroundView, at: 0)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 0).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: self.containerView.leftAnchor, constant: 0).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 0).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: 0).isActive = true
        
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        self.containerView.insertSubview(visualEffectView, at: 1)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 0).isActive = true
        visualEffectView.leftAnchor.constraint(equalTo: self.containerView.leftAnchor, constant: 0).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: 0).isActive = true
        visualEffectView.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: 0).isActive = true
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = containerView.bounds
        
        let vibrantLabel = UILabel()
        vibrantLabel.text = "PBMediaSlider"
        vibrantLabel.font = UIFont.systemFont(ofSize: 36.0)
               
        vibrancyEffectView.contentView.addSubview(vibrantLabel)
        visualEffectView.contentView.addSubview(vibrancyEffectView)

        vibrantLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrantLabel.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 8.0).isActive = true
        vibrantLabel.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor).isActive = true
    }
    
    private func setupViews()
    {
        self.setupSliders()
        
        self.setupUISlider()
        
        self.setupOptionLabels()
        
        self.updateLabelFonts()
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    private func addSlider(_ slider: UIControl, underLabel label: UILabel, height: CGFloat = 14)
    {
        self.containerView.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 50).isActive = true
        slider.leadingAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.leadingAnchor, constant: 50).isActive = true
        slider.trailingAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.trailingAnchor, constant: -50).isActive = true
        slider.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    private func addTitleLabelFor(_ slider: PBMediaSlider) -> UILabel
    {
        let label = UILabel()
        label.tag = 998
        label.adjustsFontForContentSizeCategory = true
        if #available(iOS 15.0, *) {
            label.maximumContentSizeCategory = .large
        }
        label.text = layoutDirection == .leftToRight ? "Value:" : "تقدير"
        label.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(label)
        label.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20).isActive = true
        label.leadingAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.leadingAnchor, constant: 50).isActive = true
        return label
    }
    
    private func addValueLabelFor(_ slider: PBMediaSlider, andTitleLabel titleLabel: UILabel) -> UILabel
    {
        let label = UILabel()
        label.tag = 999
        label.adjustsFontForContentSizeCategory = true
        if #available(iOS 15.0, *) {
            label.maximumContentSizeCategory = .large
        }
        label.text = String(format: "%.02f", slider.value)
        self.containerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8).isActive = true
        return label
    }
    
    private func updateLabelFonts()
    {
        for subview: AnyObject in self.view.subviews {
            if let label = subview as? UILabel, label.tag == 998 {
                label.font = UIFont.preferredFont(forTextStyle: .headline, weight: .regular, fontDesign: .rounded)
            }
        }
        for subview: AnyObject in self.containerView.subviews {
            if let label = subview as? UILabel, label.tag == 998 {
                label.font = UIFont.preferredFont(forTextStyle: .headline, weight: .regular, fontDesign: .rounded)
            }
            if let label = subview as? UILabel, label.tag == 999 {
                label.font = UIFont.preferredMonospacedFont(for: .headline, weight: .regular, maxPointSize: 1000)
            }
        }
    }
    
    private func updateLabelColors()
    {
        if let color = self.view.backgroundColor {
            valueLabel.textColor = color.contrastingColor()
            enabledLabel.textColor = color.contrastingColor()
            modeLabel.textColor = color.contrastingColor()
            
            self.navigationController?.navigationBar.tintColor = color.contrastingColor()
            let barAppearance = UINavigationBarAppearance()
            barAppearance.configureWithOpaqueBackground()
            barAppearance.titleTextAttributes = [.foregroundColor: color.contrastingColor()]
            navigationItem.compactAppearance = barAppearance
            navigationItem.standardAppearance = barAppearance
        }
    }

    private func setupSliders()
    {
        self.slider1 = PBMediaSlider(frame: CGRect(x: 50, y: 100, width: self.containerView.bounds.width - 100, height: 14), value: 10.0, inRange: 0...100, activeFillColor: activeFillColor, fillColor: fillColor, emptyColor: emptyColor)
        slider1.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        //slider1.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial), style: .fill)
        //slider1.imagesEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial), style: .fill)
        slider1.feedbackStyle = .heavy
        slider1.sliderIntrinsicHeight = 14
        slider1.isContinuous = true
        slider1.addTarget(self, action: #selector(sliderViewValueChanged(_ :)), for: .valueChanged)
        slider1.minimumValueImage = UIImage(systemName: "speaker.fill")
        slider1.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        
        self.containerView.addSubview(slider1)

        let titleLabel1 = self.addTitleLabelFor(slider1)
        self.valueLabel1 = self.addValueLabelFor(slider1, andTitleLabel: titleLabel1)

        self.slider2 = PBMediaSlider()
        slider2.minimumValue = 50.0
        slider2.maximumValue = 200.0
        slider2.value = 60.0
        slider2.wideningFactor = 1.06
        slider2.emptyColor = nil
        slider2.fillColor = nil
        slider2.activeFillColor = nil
        slider2.addTarget(self, action: #selector(sliderViewValueChanged(_ :)), for: .valueChanged)
        slider2.minimumValueImage = UIImage(systemName: "speaker.fill")
        slider2.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        
        self.addSlider(slider2, underLabel: valueLabel1, height: 24)
        
        let titleLabel2 = self.addTitleLabelFor(slider2)
        self.valueLabel2 = self.addValueLabelFor(slider2, andTitleLabel: titleLabel2)

        self.slider3 = PBMediaSlider()
        slider3.value = 0.5
        slider3.addTarget(self, action: #selector(sliderViewValueChanged(_ :)), for: .valueChanged)
        slider3.addTarget(self, action: #selector(sliderTouchUpInside(_ :)), for: .touchUpInside)
        
        self.addSlider(slider3, underLabel: valueLabel2)
        
        let titleLabel3 = self.addTitleLabelFor(slider3)
        self.valueLabel3 = self.addValueLabelFor(slider3, andTitleLabel: titleLabel3)

        self.slider4 = PBMediaSlider()
        slider4.style = .progress
        slider4.minimumValue = 0.0
        slider4.maximumValue = 5400.0
        slider4.value = 0.0
        /*
        let text = String(format: "%.02f", slider4.value)
        slider4.elapsedTimeLabel.text = text
        let remainingValue = slider4.maximumValue - slider4.value
        let remainingText = String(format: "%.02f", remainingValue)
        slider4.remainingTimeLabel.text = remainingText
        */
        //slider4.labelsEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial), style: .label)

        slider4.addTarget(self, action: #selector(sliderViewValueChanged(_ :)), for: .valueChanged)
        slider4.addTarget(self, action: #selector(sliderTouchDown(_ :)), for: .touchDown)
        slider4.addTarget(self, action: #selector(sliderTouchUpInside(_ :)), for: .touchUpInside)
        slider4.addTarget(self, action: #selector(sliderTouchUpOutside(_ :)), for: .touchUpInside)
        slider4.addTarget(self, action: #selector(sliderTouchDragExit(_ :)), for: .touchDragExit)
        slider4.addTarget(self, action: #selector(sliderTouchDragEnter(_ :)), for: .touchDragEnter)
        slider4.addTarget(self, action: #selector(sliderTouchDragInside(_ :)), for: .touchDragInside)
        slider4.addTarget(self, action: #selector(sliderTouchDragOutside(_ :)), for: .touchDragOutside)
        
        self.cancellablePublisher4 = slider4.publisher(for: .valueChanged).sink { slider in
            if let slider = slider as? PBMediaSlider {
                print("slider4 value: \(slider.value)")
            }
        }
        
        self.addSlider(slider4, underLabel: valueLabel3, height: 36)
        
        let titleLabel4 = self.addTitleLabelFor(slider4)
        self.valueLabel4 = self.addValueLabelFor(slider4, andTitleLabel: titleLabel4)
    }
    
    private func setupUISlider()
    {
        self.uislider = UISlider()
        self.uislider.semanticContentAttribute = self.view.semanticContentAttribute
        uislider.minimumValueImage = UIImage(systemName: "speaker.fill")
        uislider.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        uislider.addTarget(self, action: #selector(uisliderValueChanged(_ :)), for: .valueChanged)
        uislider.addTarget(self, action: #selector(uisliderTouchUpInside(_ :)), for: .touchUpInside)
        uislider.addTarget(self, action: #selector(uisliderTouchDown(_ :)), for: .touchDown)
        uislider.addTarget(self, action: #selector(uisliderTouchDragExit(_ :)), for: .touchDragExit)
        uislider.addTarget(self, action: #selector(uisliderTouchDragEnter(_ :)), for: .touchDragEnter)
        uislider.addTarget(self, action: #selector(uisliderTouchDragInside(_ :)), for: .touchDragInside)
        uislider.addTarget(self, action: #selector(uisliderTouchDragOutside(_ :)), for: .touchDragOutside)
                
        self.addSlider(uislider, underLabel: valueLabel4, height: 30)
    }
    
    private func setupOptionLabels()
    {
        self.enabledLabel.text = layoutDirection == .rightToLeft ? "ممكّن" : "Enabled"
        self.valueLabel.text = layoutDirection == .rightToLeft ? "اضبط القيمة على" : "Set Value To"
        self.modeLabel.text = layoutDirection == .rightToLeft ? "الوضع المظلم" : "Dark Mode"
    }
    
    @objc private func changeLayoutDirection(_ sender: UIBarButtonItem)
    {
        var rtlDirection = UserDefaults.standard.bool(forKey: rtlKey)
        rtlDirection.toggle()
        UserDefaults.standard.setValue(rtlDirection, forKey: rtlKey)
        UserDefaults.standard.synchronize()
        let alert = UIAlertController(title: "PBMediaSlider", message: "Kill and restart the app!", preferredStyle: .alert)
        self.present(alert, animated: true)
    }

    @objc private func changeBackground(_ sender: UIBarButtonItem)
    {
        let image = UIImage(named: String(format: "Cover%02d", Int.random(in: 1...23)))
        self.view.backgroundColor = image?.averageColor
        self.backgroundView.image = image
        self.updateLabelColors()
    }

    // MARK: - PBMediaSlider Events
    
    @objc private func sliderViewValueChanged(_ slider: PBMediaSlider)
    {
        //print("progress: \(slider.progress)")
        let text = String(format: "%.02f", slider.value)
        switch slider {
        case slider1:
            valueLabel1.text = text
        case slider2:
            valueLabel2.text = text
        case slider3:
            valueLabel3.text = text
        case slider4:
            valueLabel4.text = text
            /*
            slider.elapsedTimeLabel.text = text
            let remainingValue = slider.maximumValue - slider.value
            let remainingText = String(format: "%.02f", remainingValue)
            slider.remainingTimeLabel.text = remainingText
            */
        default:
            break
        }
    }

    @objc private func sliderTouchDown(_ slider: PBMediaSlider) {
        print("slider touchDown")
    }
    
    @objc private func sliderTouchUpInside(_ slider: PBMediaSlider) {
        print("slider touchUpInside")
    }
    
    @objc private func sliderTouchUpOutside(_ slider: PBMediaSlider) {
        print("slider touchUpOutside")
    }
    
    @objc private func sliderTouchDragInside(_ slider: PBMediaSlider) {
        print("slider touchDragInside")
    }
    
    @objc private func sliderTouchDragOutside(_ slider: PBMediaSlider) {
        print("slider touchDragOutside")
    }
    
    @objc private func sliderTouchDragExit(_ slider: PBMediaSlider) {
        print("slider touchDragExit")
    }

    @objc private func sliderTouchDragEnter(_ slider: PBMediaSlider) {
        print("slider touchDragEnter")
    }

    // MARK: - UISlider Events
    
    @objc private func uisliderValueChanged(_ slider: UISlider) {
        print("uislider valueChanged")
    }
    
    @objc private func uisliderTouchUpInside(_ slider: UISlider) {
        print("uislider touchUpInside")
    }
    
    @objc private func uisliderTouchDown(_ slider: UISlider) {
        print("uislider touchDown")
    }

    @objc private func uisliderTouchDragInside(_ slider: UISlider) {
        print("uislider touchDragInside")
    }
    
    @objc private func uisliderTouchDragOutside(_ slider: UISlider) {
        print("uislider touchDragOutside")
    }
    
    @objc private func uisliderTouchDragExit(_ slider: UISlider) {
        print("uislider touchDragExit")
    }

    @objc private func uisliderTouchDragEnter(_ slider: UISlider) {
        print("uislider touchDragEnter")
    }

    // MARK: - IBAction Callbacks
    
    @IBAction func enableSliders(_ sender: UISwitch)
    {
        self.slider1.isEnabled.toggle()
        self.slider2.isEnabled.toggle()
        self.slider3.isEnabled.toggle()
        self.slider4.isEnabled.toggle()
        self.uislider.isEnabled.toggle()
    }
    
    @IBAction func changeValueAnimated(_ sender: UIButton)
    {
        let text = String(format: "%.02f", 0.50)
        slider1.setValue(0.5, animated: true)
        valueLabel1.text = text
        //slider2.setValue(0.5, animated: true) // 0...200
        //valueLabel2.text = text
        slider3.setValue(0.5, animated: true)
        valueLabel3.text = text
        slider4.setProgress(0.5, animated: true) // 0...5400 (1h30)
        valueLabel4.text = String(format: "%d", 5400 / 2)
        if let uislider = self.uislider {
            uislider.setValue(0.5, animated: true)
        }
    }
    
    @IBAction func overrideInterfaceStyle(_ sender: Any)
    {
        let userInterfaceStyle = self.traitCollection.userInterfaceStyle
        self.overrideUserInterfaceStyle = userInterfaceStyle == .light ? .dark : .light
        self.navigationController?.overrideUserInterfaceStyle = userInterfaceStyle == .light ? .dark : .light
    }
}

// MARK: - ViewController Preview

@available(iOS 17, *)
#Preview {
  let storyboard = UIStoryboard(name: "Main", bundle: nil)
  let vc = storyboard.instantiateInitialViewController() as! UINavigationController
  vc.loadViewIfNeeded()
  return vc
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    convenience init(
        light lightModeColor: @escaping @autoclosure () -> UIColor,
        dark darkModeColor: @escaping @autoclosure () -> UIColor
     ) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return lightModeColor()
            case .dark:
                return darkModeColor()
            case .unspecified:
                return lightModeColor()
            @unknown default:
                return lightModeColor()
            }
        }
    }
    
    /// returns true if is a dark color
    var isDarkColor: Bool {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return  lum < 0.45
    }
    
    /// Generates contrasting color for dark and light userInterfaceStyles
    /// - Returns: UIColor.white for dark colors else return UIColor.black
    func contrastingColor() -> UIColor {
        let dark = self.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let light = self.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        
        return UIColor(light: light.isDarkColor ? .white : .black,
                       dark: dark.isDarkColor ? .white : .black)
    }
    
}

