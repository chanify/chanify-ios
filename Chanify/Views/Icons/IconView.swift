//
//  IconView.swift
//  Chanify
//
//  Created by WizJin on 2021/4/25.
//

import SwiftUI

struct IconView: View {
    var iconImage: Image
    var tintColor: UIColor
    var backgroundColor: UIColor
    
    init(icon: String?) {
        var image: Image? = nil
        var tint: UIColor? = nil
        var bkgColor: UIColor? = nil
        if let components = URLComponents(string: icon ?? "") {
            if components.scheme == "sys" {
                if let host = components.host {
                    image = Image(systemName: host)
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
        iconImage = image ?? Image("Channel")
        tintColor = tint ?? UIColor.white
        backgroundColor = bkgColor ?? UIColor(named: "AccentColor")!
    }
    
    init(icon: Image, tint: UIColor, background: UIColor) {
        iconImage = icon
        tintColor = tint
        backgroundColor = background
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: size*0.2)
                    .fill(Color(backgroundColor))
                    .frame(width: size, height: size, alignment: .center)
                self.iconImage
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(tintColor))
                    .frame(width: size*0.60, height: size*0.60, alignment: .center)

            }.offset(x: (geometry.size.width - size)/2.0, y: (geometry.size.height - size)/2.0)
        }
    }
}

//struct IconView_Previews: PreviewProvider {
//    static var previews: some View {
//        IconView(icon: "sys://house")
//    }
//}
