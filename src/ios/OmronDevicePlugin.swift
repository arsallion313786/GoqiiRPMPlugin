import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(OmronDevicePlugin) class OmronDevicePlugin: CDVPlugin {
    
    // MARK: - Properties
    var eventCallbackId: String? // Single persistent callback
    var bluetoothManager: CBCentralManager!
    var connectionTimeoutWorkItem: DispatchWorkItem?
    var discoveryTimer: DispatchWorkItem?
    
    var customTimeoutMs: Double = 10000.0 // Default 10s (matching new code)
    var discoveredDevices: [[String: Any]] = []
    var hasNotifiedPairingSuccess: Bool = false

    override func pluginInitialize() {
        print("🟢 Omron pluginInitialize called")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // Initialize the SDK internal state early
        OmronBluetoothManager.sharedInstance.initaliseBle()
    }

    // MARK: - Event Dispatchers
    
    private func sendEvent(data: [String: Any], status: CDVCommandStatus = .ok) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: No persistent callback registered.")
            return
        }
        let pluginResult = CDVPluginResult(status: status, messageAs: data)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    // MARK: - Cordova Actions

    @objc(registerCallback:)
    func registerCallback(command: CDVInvokedUrlCommand) {
        self.eventCallbackId = command.callbackId
        let result = CDVPluginResult(status: .noResult)
        result?.setKeepCallbackAs(true)
        self.commandDelegate.send(result, callbackId: command.callbackId)
        print("🔵 Persistent callback registered.")
    }

    @objc(initializeSDK:)
    func initializeSDK(command: CDVInvokedUrlCommand) {
        OmronBluetoothManager.sharedInstance.delegate = self
        OmronBluetoothManager.sharedInstance.initaliseBle()
        
        // Immediate ACK
        let result = CDVPluginResult(status: .ok, messageAs: "Initialization started")
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(startDeviceDiscovery:)
    func startDeviceDiscovery(command: CDVInvokedUrlCommand) {
        guard bluetoothManager.state == .poweredOn else {
            let error = ["code": "BLUETOOTH_OFF", "msg": "Bluetooth is disabled."]
            sendEvent(data: error, status: .error)
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: error), callbackId: command.callbackId)
            return
        }

        self.discoveredDevices.removeAll()
        OmronBluetoothManager.sharedInstance.startScanning()
        
        discoveryTimer?.cancel()
        discoveryTimer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            OmronBluetoothManager.sharedInstance.stopSearch()
            
            if self.discoveredDevices.isEmpty {
                self.sendEvent(data: [
                    "code": "DEVICE_NOT_FOUND",
                    "data": [],
                    "msg": "Devices Found"
                ])
//                self.sendEvent(data: ["code": "DEVICE_NOT_FOUND", "msg": "No devices found."], status: .error)
            } else {
                self.sendEvent(data: [
                    "code": "ON_DEVICE_FOUND",
                    "data": self.discoveredDevices,
                    "msg": "Devices Found"
                ])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.customTimeoutMs/1000.0, execute: discoveryTimer!)
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }
    
    
    @objc(stopDeviceDiscovery:)
    func stopDeviceDiscovery(command: CDVInvokedUrlCommand){
        discoveryTimer?.cancel()
        OmronBluetoothManager.sharedInstance.stopSearch()
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }

    @objc(pairBPMWithId:)
    func pairBPMWithId(command: CDVInvokedUrlCommand) {
        guard let targetMacId = command.argument(at: 0) as? String, !targetMacId.isEmpty else {
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: "Missing MAC ID"), callbackId: command.callbackId)
            return
        }
        
        hasNotifiedPairingSuccess = false
        OmronBluetoothManager.sharedInstance.stopSearch()
        OmronBluetoothManager.sharedInstance.connectOmronWithUUID(targetMacId)
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }

    @objc(connectAndSync:)
    func connectAndSync(command: CDVInvokedUrlCommand) {
        OmronBluetoothManager.sharedInstance.connectAndSync()
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }

    @objc(disconnectOnlyBLE:)
    func disconnectOnlyBLE(command: CDVInvokedUrlCommand) {
        OmronBluetoothManager.sharedInstance.disconnectOnlyBLE()
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }

    @objc(unlink:)
    func unlink(command: CDVInvokedUrlCommand) {
        OmronBluetoothManager.sharedInstance.disconnect()
        sendEvent(data: ["code": "UNLINK", "msg": "Unlinked device"])
        self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
    }
    
    @objc(setConnectionTimeout:)
    func setConnectionTimeout(command: CDVInvokedUrlCommand) {
        if let ms = command.argument(at: 0) as? Double {
            self.customTimeoutMs = ms
            self.commandDelegate.send(CDVPluginResult(status: .ok), callbackId: command.callbackId)
        }
    }
}

// MARK: - OmronBluetoothManagerDelegate
extension OmronDevicePlugin: OmronBluetoothManagerDelegate {

    func didInitialize(isSuccessfully: Bool) {
        sendEvent(data: [
            "code": "INITIALIZE_SUCCESSFULLY",
            "isSuccessfully": isSuccessfully,
            "msg": "Initialize complete"
        ])
    }

    func didFindDevice(isSuccessfully: Bool, deviceName: String, macId: String, deviceType: String, rssi: Int, advData: [String: Any]) {
        let isDuplicate = discoveredDevices.contains { ($0["id"] as? String) == macId }
        if !isDuplicate {
            let deviceModel: [String: Any] = [
                "name": deviceName,
                "id": macId,
                "deviceType": deviceType,
                "rssi": rssi,
                "advData": advData
            ]
            discoveredDevices.append(deviceModel)
        }
    }

    func onPairingSuccess() {
        if !hasNotifiedPairingSuccess {
            sendEvent(data: ["code": "ON_PAIRING_SUCCESS", "isSuccessfully": true])
            hasNotifiedPairingSuccess = true
        }
    }

    func didConnectDevice(isSuccessfully: Bool, macId: String) {
        sendEvent(data: [
            "code": "DEVICE_CONNECTED",
            "isSuccessfully": isSuccessfully,
            "state": isSuccessfully ? "connected" : "disconnected",
            "macId": macId
        ])
    }

    func didReceiveBloodPressureData(_ data: [String: Any]) {
        let payload = data.isEmpty ? [] : [data] // Kept as array for JS consistency
        sendEvent(data: [
            "code": "ON_DATA_RECEIVED",
            "data": payload,
            "msg": data.isEmpty ? "No new records" : "Data received"
        ])
    }

    func didDisconnectDevice(isSuccessfully: Bool) {
        sendEvent(data: ["code": "DEVICE_DISCONNECTED", "state": "disconnected"])
    }

    func didDeviceDisconnectedAndTryingToConnect(isSuccessfully: Bool) {
        sendEvent(data: ["code": "DEVICE_RECONNECTING", "msg": "Attempting auto-reconnect"])
    }
    
    func didDisconnectOnlyBLEDevice(isSuccessfully: Bool) {
        sendEvent(data: ["code": "DISCONNECTED_BLE", "msg": "Physical link dropped"])
    }
}

// MARK: - CBCentralManagerDelegate
extension OmronDevicePlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let states: [CBManagerState: String] = [
            .poweredOn: "POWERED_ON",
            .poweredOff: "POWERED_OFF",
            .unauthorized: "UNAUTHORIZED"
        ]
        sendEvent(data: [
            "code": "BLUETOOTH_STATE_CHANGED",
            "state": states[central.state] ?? "OTHER"
        ])
    }
}
