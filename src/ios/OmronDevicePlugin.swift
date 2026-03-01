//swift
import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(OmronDevicePlugin) class OmronDevicePlugin: CDVPlugin {
    
    // 1. Single callback for all asynchronous events
    var eventCallbackId: String?
    
    var bluetoothManager: CBCentralManager!
    var connectionTimeoutWorkItem: DispatchWorkItem?
    var customTimeoutMs: Double = 30000.0 // Default to 30 seconds
    var isOmronDeviceFoundDuringScan = false
    
    override func pluginInitialize() {
        print("🟢 Omron pluginInitialize called")
        // Initialize Bluetooth manager to check its state
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // The GOQiiSDK's Omron manager should be initialized via the `initializeSDK` call.
    }

    // MARK: - Event Dispatchers
    
    /// Sends a success event to the persistent JavaScript callback.
    private func sendEvent(data: [String: Any]) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: eventCallbackId is not set. Cannot send event: \(data["code"] ?? "N/A")")
            return
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: data)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback channel open
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    /// Sends an error event to the persistent JavaScript callback.
    private func sendErrorEvent(data: [String: Any]) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: eventCallbackId is not set. Cannot send error event: \(data["code"] ?? "N/A")")
            return
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: data)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback channel open
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    // MARK: - Cordova Action Handlers

    /// Registers the single persistent callback for all plugin events.
    @objc(registerCallback:)
    func registerCallback(command: CDVInvokedUrlCommand) {
        print("🔵 registerCallback called")
        self.eventCallbackId = command.callbackId
        
        // Send an initial "NO_RESULT" to keep the callback alive.
        let pluginResult = CDVPluginResult(status: .noResult)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Initializes the underlying Omron SDK.
    @objc(initializeSDK:)
    func initializeSDK(command: CDVInvokedUrlCommand) {
        print("🟢 initializeSDK called")
        OmronBluetoothManager.sharedInstance.delegate = self
        OmronBluetoothManager.sharedInstance.initaliseBle()
        // The result is sent via the `didInitialize` delegate method.
        // We can send an immediate acknowledgment if desired.
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "SDK initialization process started.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Checks if an Omron device has been previously paired.
    @objc(isDevicePaired:)
    func isDevicePaired(command: CDVInvokedUrlCommand) {
        let isPaired = OmronBluetoothManager.sharedInstance.isBloodPressureDevicePresent()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isPaired)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    /// Checks the current physical connection state of the device.
    @objc(isDeviceConnected:)
    func isDeviceConnected(command: CDVInvokedUrlCommand) {
        let isConnected = OmronBluetoothManager.sharedInstance.isCurrentlyConnected()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isConnected)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Starts scanning for Omron devices.
    @objc(startDeviceDiscovery:)
    func startDeviceDiscovery(command: CDVInvokedUrlCommand) {
        print("🔍 startDeviceDiscovery called")
        
        guard bluetoothManager.state == .poweredOn else {
            let result = ["code": "BLUETOOTH_OFF", "msg": "Bluetooth is not enabled."]
            self.sendErrorEvent(data: result)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: result)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        isOmronDeviceFoundDuringScan = false
        OmronBluetoothManager.sharedInstance.startScanning()
        startConnectionTimeout(for: "Scan") { [weak self] in
            guard let self = self, !self.isOmronDeviceFoundDuringScan else { return }
            print("🛑 Scan timeout: No Omron device found.")
            OmronBluetoothManager.sharedInstance.stopSearch()
            self.sendErrorEvent(data: ["code": "DEVICE_NOT_FOUND", "msg": "Scan timed out. No Omron device was found."])
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Device discovery started.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Initiates pairing with an Omron BPM device.
    @objc(pairBPM:)
    func pairBPM(command: CDVInvokedUrlCommand) {
        print("🔗 pairBPM called")
        OmronBluetoothManager.sharedInstance.pairBPM()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Pairing process initiated.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Connects to a known device and syncs data.
    @objc(connectAndSync:)
    func connectAndSync(command: CDVInvokedUrlCommand) {
        print("🔄 connectAndSync called")
        startConnectionTimeout(for: "Sync") { [weak self] in
            self?.sendErrorEvent(data: ["code": "TIMEOUT_EXCEEDED", "msg": "Sync timed out. Please ensure your device is on."])
        }
        OmronBluetoothManager.sharedInstance.connectAndSync()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Connection and sync process initiated.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Unlinks (forgets) the paired Omron device.
    @objc(unlink:)
    func unlink(command: CDVInvokedUrlCommand) {
        print("🔌 unlink called")
        OmronBluetoothManager.sharedInstance.disconnect() // Assuming this also handles unpairing
        let result = ["code": "UNLINK_SUCCESS", "msg": "Unlink command sent successfully."]
        sendEvent(data: result)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: result)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    /// Gets the MAC address of the currently paired device.
    @objc(getCurrentDeviceMacId:)
    func getCurrentDeviceMacId(command: CDVInvokedUrlCommand) {
        let macId = OmronBluetoothManager.sharedInstance.getCurrentDeviceMacId() ?? ""
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: macId)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Sets the connection timeout duration.
    @objc(setConnectionTimeout:)
    func setConnectionTimeout(command: CDVInvokedUrlCommand) {
        if let ms = command.argument(at: 0) as? Double {
            self.customTimeoutMs = ms
            print("⏱️ Connection timeout set to: \(ms)ms")
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Timeout updated.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Invalid timeout value provided.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    // MARK: - Timeout Helpers
    
    private func startConnectionTimeout(for operation: String, onTimeout: @escaping () -> Void) {
        cancelConnectionTimeout() // Cancel any existing timer
        let workItem = DispatchWorkItem(block: onTimeout)
        self.connectionTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.customTimeoutMs / 1000.0), execute: workItem)
        print("⏳ Started \(operation) timeout for \(self.customTimeoutMs)ms.")
    }

    private func cancelConnectionTimeout() {
        self.connectionTimeoutWorkItem?.cancel()
        self.connectionTimeoutWorkItem = nil
    }
}

// MARK: - CBCentralManagerDelegate
extension OmronDevicePlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state: String
        switch central.state {
            case .poweredOn: state = "POWERED_ON"
            case .poweredOff: state = "POWERED_OFF"
            default: state = "OTHER"
        }
        print("Bluetooth state changed: \(state)")
        sendEvent(data: ["code": "BLUETOOTH_STATE_CHANGED", "state": state])
    }
}

// MARK: - OmronBluetoothManagerDelegate
extension OmronDevicePlugin: OmronBluetoothManagerDelegate {

    func didInitialize(isSuccessfully: Bool) {
        let result: [String: Any] = [
            "code": isSuccessfully ? "INITIALIZE_SUCCESS" : "INITIALIZE_FAILURE",
            "isSuccessfully": isSuccessfully,
            "msg": "Omron SDK initialization complete."
        ]
        sendEvent(data: result)
    }

    func didFindDevice(isSuccessfully: Bool, deviceName: String, macId: String, deviceType: String, rssi: Int) {
        print("📡 didFindDevice delegate: \(deviceName)")
        cancelConnectionTimeout() // A device was found, so cancel the scan timeout
        isOmronDeviceFoundDuringScan = true
        
        let device: [String: Any] = [
            "code": "ON_DEVICE_FOUND",
            "name": deviceName,
            "macId": macId,
            "rssi": rssi
        ]
        sendEvent(data: device)
    }
    
    func onPairingSuccess() {
        print("🔗 onPairingSuccess delegate")
        // This often comes right before or after didConnectDevice
        sendEvent(data: ["code": "ON_PAIRING_SUCCESS", "isSuccessfully": true, "msg": "Device paired successfully."])
    }

    func didConnectDevice(isSuccessfully: Bool, macId: String) {
        print("✅ didConnectDevice delegate: \(isSuccessfully)")
        cancelConnectionTimeout() // Connection succeeded, cancel any running timeout
        
        let result: [String: Any] = [
            "code": "DEVICE_CONNECTED",
            "isSuccessfully": isSuccessfully,
            "macId": macId,
            "state": "connected"
        ]
        sendEvent(data: result)
    }
    
    func didDisconnectDevice(isSuccessfully: Bool) {
        print("❌ didDisconnectDevice delegate")
        let result: [String: Any] = [
            "code": "DEVICE_DISCONNECTED",
            "isSuccessfully": isSuccessfully,
            "state": "disconnected"
        ]
        sendEvent(data: result)
    }

    func didReceiveBloodPressureData(_ data: [String: Any]) {
        print("🩸 didReceiveBloodPressureData delegate")
        cancelConnectionTimeout() // Data received, cancel any sync timeout
        
        guard !data.isEmpty else {
            print("⚠️ Received empty data dictionary. No new records to sync.")
            // Optionally send an event indicating no new data was found
            sendEvent(data: ["code": "ON_DATA_SYNCED_NO_NEW_RECORDS", "msg": "Sync complete, but no new data was found."])
            return
        }
        
        let result: [String: Any] = [
            "code": "ON_DATA_RECEIVED",
            "data": data,
            "msg": "Blood pressure data received."
        ]
        sendEvent(data: result)
    }

    // This delegate method seems redundant if you have didDisconnectDevice.
    // If it provides unique information, you can map it to a new event.
    func didDisconnectOnlyBLEDevice(isSuccessfully: Bool) {
        print("didDisconnectOnlyBLEDevice called - can often be ignored if using didDisconnectDevice")
    }
    
    // This seems to indicate an auto-reconnect attempt.
    func didDeviceDisconnectedAndTryingToConnect(isSuccessfully: Bool) {
        print("Device disconnected and is now auto-reconnecting...")
        sendEvent(data: ["code": "DEVICE_RECONNECTING", "msg": "Device lost connection and is attempting to reconnect."])
    }
}
