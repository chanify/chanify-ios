//
//  ContentView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var logic: LogicModel

    var body: some View {
        if logic.me == nil {
            Text("NotInit")
                .multilineTextAlignment(.center)
                .padding()
        }
        if let me = logic.me {
            Text(me.uid)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LogicModel())
    }
}
