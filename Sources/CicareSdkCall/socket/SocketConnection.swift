//
//  SocketConnection.swift
//  CicareSdkCall
//
//  Created by dutamedia on 31/07/25.
//
import Foundation
import SocketIO
open class SocketConnection {
    public static let `default` = SocketConnection()
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    private init() {}

    public func connect(url: String, token: String) {
        guard let socketURL = URL(string: url) else {
            print("Invalid URL")
            return
        }

        manager = SocketManager(socketURL: socketURL, config: [
            .log(true),
            .compress,
            .reconnects(true),
            .connectParams(["token": token])
        ])

        socket = manager?.socket(forNamespace: "/your-namespace")
        registerHandlers()
        socket?.connect()
    }

    private func registerHandlers() {
        socket?.on(clientEvent: .connect) { _, _ in
            print("✅ Socket connected")
        }
        socket?.on(clientEvent: .disconnect) { _, _ in
            print("❌ Socket disconnected")
        }
        socket?.on(clientEvent: .error) { data, _ in
            print("Socket error:", data)
        }
        socket?.on(clientEvent: .statusChange) { data, _ in
            print("Status changed:", data)
        }
        // Tambahkan handler custom event jika perlu
    }

    public func disconnect() {
        socket?.disconnect()
    }
}
