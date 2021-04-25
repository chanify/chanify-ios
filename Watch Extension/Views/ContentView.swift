//
//  ContentView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: LogicModel

    var body: some View {
        List {
            ForEach(model.nodes) { node in
                NavigationLink(destination: NodeDetailView(node: node)) {
                    NodeCell(node: node)
                        .frame(height: 50.0)
                }
            }
        }
        .navigationBarTitle(Text("Nodes"))
    }
}

struct NodeCell: View {
    var node: NodeModel
    
    var body: some View {
        HStack {
            IconView(icon: node.icon)
            VStack(alignment: .leading) {
                Text(node.name)
                    .font(.body)
                    .lineLimit(1)
                Text(node.endpoint)
                    .font(.footnote)
                    .lineLimit(1)
            }.padding(.leading, 4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LogicModel())
    }
}
