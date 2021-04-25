//
//  LogicModel.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/20.
//

import Foundation
import SwiftUI
import Combine

struct NodeModel: Identifiable {
    var id: String
    let name: String
    let icon: String?
    let version: String
    let endpoint: String
}

final class LogicModel: ObservableObject {
    @Published var me: CHUserModel? = CHLogic.shared.me
    @Published var nodes = loadNodes()
    
    static func loadNodes() ->[NodeModel] {
        var nodes = [NodeModel]()
        if let ds = CHLogic.shared.userDataSource {
            for model in ds.loadNodes() {
                nodes.append(NodeModel(id: model.nid, name: model.name, icon: model.icon, version: model.version, endpoint: model.endpoint))
            }
        }
        return nodes;
    }
}
