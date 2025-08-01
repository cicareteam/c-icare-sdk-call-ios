import Foundation
import SocketIO
import WebRTC

protocol CallEventListener: AnyObject {
    func onCallStateChanged(_ state: CallStatus)
}

enum SocketIOClientStatus: String {
    case connected
    case disconnected
}

class SocketManagerSignaling: NSObject {
    
    public static let shared = SocketManagerSignaling()
    
    private let webrtcManager: WebRTCManager = WebRTCManager.init()
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    private override init() {
        super.init()
        self.webrtcManager.callback = self
    }
    
    func convertToWebSocket(url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme else {
            return nil
        }
        switch scheme.lowercased() {
        case "https":
            components.scheme = "wss"
        case "http":
            components.scheme = "ws"
        default:
            break
        }
        return components.url
    }

    func connect(wssUrl: URL, token: String, completion: @escaping (SocketIOClientStatus) -> Void) {
        manager = SocketManager(socketURL: wssUrl,
                                    config: [.log(false),
                                             .compress,
                                             .reconnects(true),
                                             .connectParams(["token": token])])
        socket = manager?.socket(forNamespace: "/")
        socket?.on(clientEvent: .statusChange) { data, _ in
            print("data socket status: \(data)")
                if let status = data.first as? SocketIOClientStatus {
                    completion(status)
                }
        }
        socket?.on(clientEvent: .connect) { _, _ in
            print("Transport:")
            completion(.connected)
        }
        socket?.on(clientEvent: .disconnect) { _, _ in
            completion(.disconnected)
        }


        registerHandlers()
        socket?.connect()
    }
    
    func initCall(completion: @escaping (Bool) -> Void) {
        self.webrtcManager.createOffer { result in
            switch result {
            case .success(let sdpDesc):
                // Kirim payload SDP ke server kapan reply lewat signaling
                let sdpPayload: [String: Any] = [
                    "type": sdpDesc.type.rawValue,
                    "sdp": sdpDesc.sdp
                ]
                let payload: [String: Any] = [
                    "is_caller": true,
                    "sdp": sdpPayload
                ]
                self.send(event: "INIT_CALL", data: payload)
                completion(true)
            case .failure(let error):
                print("Failed to create offer:", error.localizedDescription)
                completion(false)
            }
        }
    }

    private func registerHandlers() {
        socket?.on(clientEvent: .error) { error, arg  in print("socket error: \(error) \(arg)")
        }
        socket?.on(clientEvent: .statusChange) { data, _ in
            print("data socket status: \(data)")
        }
        socket?.on("ACCEPTED") { _, _ in
            self.onCallStateChanged(.connected)
        }
        socket?.on("RINGING") { _, _ in
            self.onCallStateChanged(.ringing)
        }
        socket?.on("HANGUP") { _, _ in
            self.onCallStateChanged(.ended)
            self.webrtcManager.close()
            self.socket?.disconnect()
        }
        socket?.on("SDP_OFFER") { data, _ in
            print("SDP OFFER RECEIVED")
            guard let dict = data.first as? [String: Any],
                  let sdpStr = dict["sdp"] as? String else { return }
            DispatchQueue.main.async {
                self.onCallStateChanged(.connecting)
                self.webrtcManager.initMic()
                let sdp = RTCSessionDescription(type: .offer, sdp: sdpStr)
                self.webrtcManager.setRemoteDescription(sdp: sdp)
            }
        }
        socket?.on("SDP_ANSWER") { data, _ in
            print("SDP ANSWER RECEIVED")
            guard let dict = data.first as? [String: Any],
                  let sdpStr = dict["sdp"] as? String else { return }
            let sdp = RTCSessionDescription(type: .answer, sdp: sdpStr)
            self.webrtcManager.setRemoteDescription(sdp: sdp)
        }
    }

    func send(event: String, data: [String: Any]) {
        socket?.emit(event, data)
    }

    func disconnect() {
        socket?.disconnect()
    }
    
    func onCallStateChanged(_ state: CallStatus) {
        switch state {
        case .connected:
            CallService.sharedInstance.postCallStatus(state)
            break
        case .ringing:
            CallService.sharedInstance.postCallStatus(state)
            break
        case .ended:
            CallService.sharedInstance.endCall()
            break
        default:
            break
        }
        print("call state change \(state)")
    }
    
}

extension SocketManagerSignaling: WebRTCEventCallback {
    func onLocalSdpCreated(sdp: RTCSessionDescription) {
        send(event: "SDP_OFFER", data: ["sdp": sdp.sdp])
    }
    func onIceCandidateGenerated(candidate: RTCIceCandidate) {
        send(event: "ICE_CANDIDATE", data: ["candidate": candidate.sdp])
    }
    func onRemoteStreamReceived(stream: RTCMediaStream) {
        // optional: handle remote media stream
    }
    func onConnectionStateChanged(state: RTCPeerConnectionState) {
        // optional: map state to callEventListener if needed
    }
    func onIceConnectionStateChanged(state: RTCIceConnectionState) {
        switch state {
        case .disconnected:
            NotificationCenter.default.post(name: .callNetworkChanged, object: nil, userInfo: ["signalStrength": "disconnected"])
            break
        case .failed:
            NotificationCenter.default.post(name: .callNetworkChanged, object: nil, userInfo: ["signalStrength": "weak"])
            break
        case .closed:
            NotificationCenter.default.post(name: .callNetworkChanged, object: nil, userInfo: ["signalStrength": "lost"])
            break
        case .connected, .completed:
            NotificationCenter.default.post(name: .callNetworkChanged, object: nil, userInfo: ["signalStrength": "connected"])
            break
        default:
            NotificationCenter.default.post(name: .callNetworkChanged, object: nil, userInfo: ["signalStrength": "other"])
            break
        }
    }
    func onIceGatheringStateChanged(state: RTCIceGatheringState) {}
}
