//
//  NodeDetailView.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/25.
//

import SwiftUI

struct NodeDetailView: View {
    let node: NodeModel
    @State private var processStatus = 0
    @State private var showingUpdateAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack {
                VStack(alignment: .leading) {
                    if node.id != "sys" {
                        Text("NodeID")
                            .font(.title3)
                        Text(node.id)
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Version")
                            .font(.title3)
                        Text(node.version)
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Text("Endpoint")
                        .font(.title3)
                    Text(node.endpoint)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding()

                if node.id != "sys" {
                    Spacer()
                    Button("Update") {
                        CHLogic.shared.updateNodeInfo(node.id) { code in
                            if code == .OK {
                                processStatus = 0
                            } else {
                                processStatus = 1
                            }
                            showingUpdateAlert = true
                        }
                    }
                    .alert(isPresented: $showingUpdateAlert, content: {
                        if (processStatus == 0) {
                            return Alert(title: Text("Update node success"), message: nil, dismissButton: .default(Text("OK")))
                        } else {
                            return Alert(title: Text("Update node failed"), message: nil, dismissButton: .default(Text("OK")))
                        }
                    })
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                    .alert(isPresented: $showingDeleteAlert, content: {
                        Alert(title: Text("Delete node"), message: Text("Delete node or not?"), primaryButton: .cancel(), secondaryButton: .destructive(Text("OK"), action: {
                            CHLogic.shared.deleteNode(node.id)
                        }))
                    })
                }
            }
        }
        
        .navigationBarTitle(Text(node.name))
    }
}
