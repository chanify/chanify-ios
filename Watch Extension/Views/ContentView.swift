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
        GeometryReader { geometry in
            HStack {
                let size = geometry.size.height
                IconView(icon: node.icon)
                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 2))
                    .frame(width: size - 10, height: size, alignment: .center)
                VStack(alignment: .leading) {
                    Text(node.name)
                        .font(.body)
                        .lineLimit(1)
                    Text(node.endpoint)
                        .font(.footnote)
                        .lineLimit(1)
                }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environmentObject(LogicModel())
//    }
//}
