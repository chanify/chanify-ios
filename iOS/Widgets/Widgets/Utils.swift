//
//  Utils.swift
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/16.
//

import SwiftUI

extension ColorScheme {
    public func withAppearance(_ appearance: AppearanceEnum) -> ColorScheme {
        switch appearance {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return self
        }
    }
}
