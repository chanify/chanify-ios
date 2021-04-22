//
//  NotificationView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

struct NotificationView: View {
    var text: String?

    var body: some View {
        Text(text ?? "NewMsg").font(.body)
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
