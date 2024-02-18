//
//  UIFont+Support.swift
//  PBMediaSlider
//
//  Created by Patrick BODET on 17/02/2024.
//

import Foundation
import UIKit

public extension UIFont
{
    /// Returns an instance of the monospaced digit system font associated with the text style, specified wieght, and scaled appropriately for the user's selected content size category.
    /// - Parameters:
    ///   - style: The text style for which to return a font. See UIFont.TextStyle for recognized values.
    ///   - weight: The weight of the font, specified as a font weight constant. For a list of possible values, see "Font Weights” in UIFontDescriptor. Avoid passing an arbitrary floating-point number for weight, because a font might not include a variant for every weight.
    ///   - maxPointSize: The maximum point size value.
    /// - Returns: A font object of the specified style, weight.
    static func preferredMonospacedFont(for style: TextStyle, weight: Weight, maxPointSize: CGFloat = 25.0) -> UIFont
    {
        let metrics = UIFontMetrics(forTextStyle: style)
        let fontSize = min(UIFont.preferredFont(forTextStyle: style).pointSize, maxPointSize)
        var font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(.rounded) {
            font = UIFont.monospacedDigitSystemFont(ofSize: min(descriptor.pointSize, maxPointSize), weight: weight)
        }
        return metrics.scaledFont(for: font)
    }
    
    /// Returns an instance of the font associated with the text style, specified design, and scaled appropriately for the user's selected content size category.
    /// - Parameters:
    ///   - style: The text style for which to return a font. See UIFont.TextStyle for recognized values.
    ///   - weight: The weight of the font, specified as a font weight constant. For a list of possible values, see "Font Weights” in UIFontDescriptor. Avoid passing an arbitrary floating-point number for weight, because a font might not include a variant for every weight.
    ///   - fontDesign: The new system font design.
    /// - Returns: A font object of the specified style, weight, and design.
    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight = .regular, fontDesign: UIFontDescriptor.SystemDesign = .default) -> UIFont
    {
        let metrics = UIFontMetrics(forTextStyle: style)
        let fontSize = UIFont.preferredFont(forTextStyle: style).pointSize
        var font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        
        if let descriptor = UIFont.systemFont(ofSize: fontSize, weight: weight).fontDescriptor.withDesign(fontDesign) {
            font = UIFont(descriptor: descriptor, size: fontSize)
        }
        
        return metrics.scaledFont(for: font)
    }
}
