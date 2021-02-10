//
//  CryptoKit.swift
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

import Foundation
import CryptoKit

@objc(CHCrpyto)
class CHCrpyto : NSObject {
    @objc static func aesOpen(key: NSData, data: NSData, auth: NSData) -> NSData? {
        if let sealedBox = try? AES.GCM.SealedBox(combined: data) {
            if let txt = try? AES.GCM.open(sealedBox, using: SymmetricKey(data: Data(referencing: key)), authenticating: Data(referencing: auth)) {
                return NSData(data: txt)
            }
        }
        return nil
    }
    
    @objc static func aesSeal(key: NSData, data: NSData, nonce: NSData, auth: NSData) -> NSData? {
        if let sealedBox = try? AES.GCM.seal(data, using: SymmetricKey(data: Data(referencing: key)), nonce: AES.GCM.Nonce(data: nonce), authenticating: Data(referencing: auth)) {
            if let d = sealedBox.combined {
                return NSData(data: d)
            }
        }
        return nil
    }
}
