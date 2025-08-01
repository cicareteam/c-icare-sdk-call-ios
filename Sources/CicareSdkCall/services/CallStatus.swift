//
//  CallStatus.swift
//  CicareSdkCall
//
//  Created by cicare.team on 28/07/25.
//

import Foundation

enum CallStatus: String {
    case initializing
    case incoming
    case connected
    case connecting
    case ringing
    case calling
    case ongoing
    case ended
}

extension Notification.Name {
    static let callStatusChanged = Notification.Name("callStatusChanged")
    static let callProfileSet = Notification.Name("callProfileSet")
    static let callNetworkChanged = Notification.Name("callNetworkChanged")
}
