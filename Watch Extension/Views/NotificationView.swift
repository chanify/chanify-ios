//
//  NotificationView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

struct NotificationView: View {
    var title: String?
    var text: String?

    var body: some View {
        VStack { // (alignment: .leading)
            if let txt = title {
                if txt.count > 0 {
                    Text(txt)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
            Text(text ?? "NewMsg")
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
