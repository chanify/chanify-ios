//
//  IconView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/25.
//

import SwiftUI

struct IconView: View {
    var iconImage: UIImage
    var tintColor: UIColor
    var backgroundColor: UIColor
    
    init(icon: String?) {
        var image: UIImage? = nil
        var tint: UIColor? = nil
        var bkgColor: UIColor? = nil
        if let components = URLComponents(string: icon ?? "") {
            if components.scheme == "sys" {
                if let host = components.host {
                    image = UIImage(systemName: host)!.withRenderingMode(.alwaysTemplate)
                }
                if let items = components.queryItems {
                    for item in items {
                        if let value = item.value {
                            if item.name == "c" {
                                tint = UIColor(rgb: UInt32(value.uint64Hex()))
                            } else if (item.name == "b") {
                                bkgColor = UIColor(rgb: UInt32(value.uint64Hex()))
                            }
                        }
                    }
                }
            }
        }
        iconImage = image ?? UIImage(named: "Channel")!
        tintColor = tint ?? UIColor.white
        backgroundColor = bkgColor ?? UIColor(named: "AccentColor")!
    }

    var body: some View {
        VStack {
            Image(uiImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .foregroundColor(Color(tintColor))
                .frame(width: 40, height: 40)
        }
        .background(Color(backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
