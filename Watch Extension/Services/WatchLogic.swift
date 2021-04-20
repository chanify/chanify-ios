//
//  WatchLogic.swift
//  Watch Extension
//
//  Created by WizJin on 2021/4/20.
//

import WatchConnectivity

class WatchLogic : CHWatchLogic {
    public var model: LogicModel? = nil
    
    override init() {
        super.init()
    }

    @objc override func onUpdateUserInfo() {
        if let m = model {
            m.me = self.me
        }
    }

}
