import Foundation
import CocoaMQTT
import CryptoKit

public class DeviceClient {
    private let host: String

    private let port: UInt16

    private let deviceId: String

    private let secret: String

    private var keepAlivePeriod: UInt16

    private let useTls: Bool

    private let disableTlsVerify: Bool

    private let disableTlsHostnameVerify: Bool

    private let disableHmacSha256Verify: Bool

    private var mqttClient: CocoaMQTT?

    public init(
            host: String,
            port: UInt16,
            deviceId: String,
            secret: String,
            keepAlivePeriod: UInt16 = 120,
            useTls: Bool = false,
            disableTlsVerify: Bool = false,
            disableTlsHostnameVerify: Bool = false,
            disableHmacSha256Verify: Bool = false
    ) {
        self.host = host
        self.port = port
        self.deviceId = deviceId
        self.secret = secret
        self.keepAlivePeriod = keepAlivePeriod
        self.useTls = useTls
        self.disableTlsVerify = disableTlsVerify
        self.disableTlsHostnameVerify = disableTlsHostnameVerify
        self.disableHmacSha256Verify = disableHmacSha256Verify
    }

    func connect() throws -> Bool {
        let timestamp = TimeUtil.getTimestamp()
        let signatureType = disableHmacSha256Verify ? "0" : "1"
        let clientId = "\(deviceId)_0_\(signatureType)_\(timestamp)"

        let key = SymmetricKey(data: Data(timestamp.utf8))

        guard let hashedPasswordData = try? HMAC<SHA256>.authenticationCode(for: Data(secret.utf8), using: key).withUnsafeBytes({ Data($0) }) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to generate password"))
        }

        let password = Data(hashedPasswordData).map { String(format: "%02hhx", $0) }.joined()

        mqttClient = CocoaMQTT(clientID: clientId, host: host, port: port)
        mqttClient?.logLevel = .debug
        mqttClient?.username = deviceId
        mqttClient?.password = password

        mqttClient?.keepAlive = keepAlivePeriod

        mqttClient?.enableSSL = useTls

        if useTls && disableTlsVerify {
            mqttClient?.allowUntrustCACertificate = true
        }

        mqttClient?.connect()

        if let mqttClient = mqttClient, mqttClient.connState == .connected {
            return true
        } else {
            return false
        }
    }

    func reportDeviceMessage(
            objectDeviceId: String? = nil,
            name: String? = nil,
            id: String? = nil,
            content: Any
    ) throws {
        if mqttClient?.connState != .connected {
            throw DeviceClientError.mqttClientNotConnected
        }

        let objectDeviceId = objectDeviceId ?? deviceId

        let topic = "$oc/devices/\(objectDeviceId)/sys/messages/up"

        var messagePayload: [String: Any] = ["content": content]
        if let name = name {
            messagePayload["name"] = name
        }
        if let id = id {
            messagePayload["id"] = id
        }

        guard let data = try? JSONSerialization.data(withJSONObject: messagePayload, options: []),
              let messageString = String(data: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to generate message"))
        }

        guard let mqttClient = mqttClient else {
            throw DeviceClientError.mqttClientNotInitialized
        }

        mqttClient.publish(topic, withString: messageString, qos: .qos1)
    }

    func connState() -> CocoaMQTTConnState {
        mqttClient?.connState ?? .disconnected
    }

    func disconnect() {
        mqttClient?.disconnect()
    }
}
