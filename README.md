# PBMediaSlider

[![CI Status](https://img.shields.io/travis/iDevelopper/PBMediaSlider.svg?style=flat)](https://travis-ci.org/iDevelopper/PBMediaSlider)
[![Version](https://img.shields.io/cocoapods/v/PBMediaSlider.svg?style=flat)](https://cocoapods.org/pods/PBMediaSlider)
[![License](https://img.shields.io/cocoapods/l/PBMediaSlider.svg?style=flat)](https://cocoapods.org/pods/PBMediaSlider)
[![Platform](https://img.shields.io/cocoapods/p/PBMediaSlider.svg?style=flat)](https://cocoapods.org/pods/PBMediaSlider)
[![Swift: 5.9](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FiDevelopper%2FPBMediaSlider%2Fbadge%3Ftype%3Dswift-versions)](https://developer.apple.com/swift)
[![Swift Package Manager: compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat&logo=apple)](https://swiftpackageindex.com/iDevelopper/PBMediaSlider)

## Overview

 PBMediaSlider is a small Swift Package aiming to recreate volume and track sliders found in Apple Music on iOS 16 and later.
 PBMediaSlider maintains an API similar to built-in UISlider. It has the same properties, like value and isContinuous. Progress observation is done the same way, by adding a target and an action:

 sliderControl.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
 
 Alternatively, you can subscribe to valuePublisher publisher to receive value updates:

```Swift
 var cancellablePublisher: AnyCancellable!
 ...
 self.cancellablePublisher = slider.publisher(for: .valueChanged).sink { slider in
     if let slider = slider as? PBMediaSlider {
         print("slider value: \(slider.value)")
     }
 }
```

* Creating a slider
```Swift
        slider = PBMediaSlider(frame: CGRect(x: 50, y: 100, width: self.containerView.bounds.width - 100, height: 14), value: 10.0, inRange: 0...100, activeFillColor: activeFillColor, fillColor: fillColor, emptyColor: emptyColor)
        slider.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
```
```Swift
        slider = PBMediaSlider(frame: CGRect(x: 50, y: 100, width: self.containerView.bounds.width - 100, height: 14), activeFillColor: activeFillColor, fillColor: fillColor, emptyColor: emptyColor)
```
```Swift
        slider = PBMediaSlider()
        slider.minimumValue = 50.0
        slider.maximumValue = 200.0
        slider.value = 60.0
        slider.addTarget(self, action: #selector(sliderViewValueChanged(_ :)), for: .valueChanged)
        slider.minimumValueImage = UIImage(systemName: "speaker.fill")
        slider.maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
        self.containerView.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 50).isActive = true
        slider.leadingAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.leadingAnchor, constant: 50).isActive = true
        slider.trailingAnchor.constraint(equalTo: self.containerView.safeAreaLayoutGuide.trailingAnchor, constant: -50).isActive = true
        slider.heightAnchor.constraint(equalToConstant: height).isActive = true
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

### Swift Package Manager

`PBMediaSlider` supports SPM versions 5.1.0 and above. To use SPM, you should use Xcode 11 or above to open your project. Click `File` -> `Swift Packages` -> `Add Package Dependency`, enter `https://github.com/iDevelopper/PBMediaSlider`. Select the version you’d like to use.

### Carthage

Add the following to your Cartfile:

```github "iDevelopper/PBMediaSlider"```

Make sure you follow the Carthage integration instructions [here](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos).

### CocoaPods

`PBMediaSlider` is available for installation using the Cocoa dependency manager [CocoaPods](http://cocoapods.org/). 

Add the following to your project's Podfile:
```ruby
pod 'PBMediaSlider'
```


## Requirements

* iOS 13 or later.

## Features

* iOS 16+ Apple Music look and feel support.
* Slider and Progress control support.
* Combine subscribers support.
* Full Right-To-Left support.
* Accessibility support.
* iOS 13 dark mode support.


## Author

Patrick BODET aka iDevelopper

## License

`PBMediaSlider` is available under the MIT license, see the [LICENSE](https://github.com/iDevelopper/PBMediaSlider/blob/main/LICENSE) file for more information.

Please tell me when you use this controller in your project!

Regards,

Patrick Bodet aka iDevelopper
