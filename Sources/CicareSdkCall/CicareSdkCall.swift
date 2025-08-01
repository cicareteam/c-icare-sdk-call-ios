// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import SwiftUI

public class CicareSdkCall {
    
    private var metaData: [String: String] = [
        "initializing": "Initializing...",
        "calling": "Calling...",
        "incoming": "Incoming Call",
        "ringing": "Ringing",
        "connected": "Connected",
        "ended": "Ended",
        "answer": "Answer",
        "decline": "Decline",
        "mute": "Mute",
        "unmute": "Unmute",
        "speaker": "Speaker"
    ]
    
            
    public init() {
        
        APIService.shared.baseURL = "https://sip-gw.c-icare.cc:8443/"
        APIService.shared.apiKey = "xHNYBNtmnckl8GJXQoBSMQTz8oJsa3j5zKk5FK00Y5uOXGzwXcot7u5WM8gIpV8dFQsLNaaozMt8k3Y1fTSSxQyzOAMeuFPIzPNqJhk0GDvjHGkBBkeqZNFU5UlRF4aj"
    }
    
    public func incoming(
        callerId: String,
        callerName: String,
        callerAvatar: String,
        calleeId: String,
        calleeName: String,
        calleeAvatar: String,
        checkSum: String,
        server: String,
        token: String,
        isFormPhone: Bool,
        metaData: [String: String]?
    ) {
                let uid = UUID()
        let merged = self.metaData.merging(metaData ?? self.metaData) { _, new in new }
                CallService.sharedInstance.reportIncomingCall(id: uid, handle: callerId, callerName: callerName)
        self.showCallScreen(calleeName: callerName, callStatus: CallStatus.incoming.rawValue, avatarUrl: callerAvatar, metaData: merged)
    }

    public func outgoing(
        callerId: String,
        callerName: String,
        callerAvatar: String,
        calleeId: String,
        calleeName: String,
        calleeAvatar: String,
        checkSum: String,
        metaData: [String: String]?
    ) {
        CallService.sharedInstance.makeCall(handle: "Annas", calleeName: "CalleeName", callData: CallSessionRequest(
            callerId: callerId,
            callerName: callerName,
            callerAvatar: callerAvatar,
            calleeId: callerId,
            calleeName: calleeName,
            calleeAvatar: calleeAvatar,
            checkSum: checkSum
        ))
        let merged = self.metaData.merging(metaData ?? self.metaData) { _, new in new }
        self.showCallScreen(
            calleeName: calleeName,
            callStatus: CallStatus.initializing.rawValue,
            avatarUrl: calleeAvatar,
            metaData: merged
        )
    }

    private func getKeyWindowRootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        } else {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }
    private func showCallScreen(calleeName: String, callStatus: String, avatarUrl: String? = nil, metaData: [String: String] = [:]) {
        DispatchQueue.main.async {
            guard let topVC = self.getKeyWindowRootViewController() else {
                print("❌ Failed to find top view controller")
                return
            }
            
            if #available(iOS 13.0, *) {
                let vc = UIHostingController(rootView: CallScreenWrapper(
                    calleeName: calleeName,
                    callStatus: callStatus,
                    avatarUrl: avatarUrl,
                    metaData: metaData
                ))
                vc.modalPresentationStyle = .fullScreen
                topVC.present(vc, animated: true)
            } else {
                let vc = CallScreenViewController()
                vc.calleeName = calleeName
                vc.callStatus = callStatus
                vc.avatarUrl = avatarUrl
                vc.metaData = metaData
                vc.modalPresentationStyle = .fullScreen
                topVC.present(vc, animated: true)
            }
        }
    }


    
}

struct CallScreenWrapper: UIViewControllerRepresentable {
    var calleeName: String
    var callStatus: String
    var avatarUrl: String?
    var metaData: [String: String]

    func makeUIViewController(context: Context) -> CallScreenViewController {
        let vc = CallScreenViewController()
        vc.calleeName = calleeName
        vc.callStatus = callStatus
        vc.avatarUrl = avatarUrl
        vc.metaData = metaData
        return vc
    }

    func updateUIViewController(_ uiViewController: CallScreenViewController, context: Context) {
        // Update if needed
    }
}
