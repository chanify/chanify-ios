#!/usr/bin/env swift

import Foundation

func findDevice() -> String {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["xcrun", "simctl", "list", "-j"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    var udid = ""
    do {
        if let json = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String, Any> {
            if let devices = json["devices"] as? Dictionary<String, [Dictionary<String, Any>]> {
                for (_, devs) in devices {
                    for dev in devs {
                        if let state = dev["state"] as? String {
                            if state == "Booted" {
                                if let uid = dev["udid"] as? String {
                                    udid = uid
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch let error as NSError {
        print(error)
    }
    task.waitUntilExit()
    return udid
}

func buildAPNS() -> String {
    var body = [ "body": " " ]
    for arg in CommandLine.arguments {
        if arg.hasPrefix("text=") {
            body["text"] = String(arg.suffix(arg.count - 5))
        } else if arg.hasPrefix("image=") {
            body["image"] = String(arg.suffix(arg.count - 6))
        } else if arg.hasPrefix("link=") {
            body["link"] = String(arg.suffix(arg.count - 5))
        }
    }
    let msg = [
        "Simulator Target Bundle": "net.chanify.ios",
        "aps": [
            "mutable-content": 1,
            "alert": body
        ]
    ] as [String : Any]
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: msg, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
    } catch let error as NSError {
        print(error)
    }
    return ""
}

func sendMsg(_ udid: String, _ msg: String) -> Bool {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = ["xcrun", "simctl", "push", udid, "-"]
    let inPipe = Pipe()
    let outPipe = Pipe()
    task.standardInput = inPipe
    task.standardOutput = outPipe
    task.launch()

    let fh = inPipe.fileHandleForWriting
    fh.write(Data(msg.utf8))
    fh.closeFile()

    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: data, as: UTF8.self)
    print(output)
    task.waitUntilExit()
    return true
}

let udid = findDevice()
if !sendMsg(udid, buildAPNS()) {
    print("send failed: ", udid)
}
