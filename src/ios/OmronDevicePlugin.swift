import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(OmronDevicePlugin)
class OmronDevicePlugin: CDVPlugin {
    
    // Single, persistent callback context for all events, just like the Android version.
    var eventCallbackContext: String?
    var bluetoothManager: CBCentralManager!

    // MARK: - Plugin Lifecycle
    
    override func pluginInitialize() {
        super.pluginInitialize()
        print("🟢 Omron Plugin Initialized")
        // Initialize the Bluetooth manager to check its state.
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // Set this class as the delegate for Omron events.
        OmronBluetoothManager.sharedInstance.delegate = self
    }

    // MARK: - Plugin Actions (Called from JavaScript)

    @objc(initialize:)
    func initialize(command: CDVInvokedUrlCommand) {
        print("🔵 initialize called")
        // The SDK is initialized and a success message is sent back immediately.
        // Asynchronous initialization status will be sent via the persistent event callback.
        OmronBluetoothManager.sharedInstance.initaliseBle()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Omron SDK initialization process started.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(registerCallback:)
    func registerCallback(command: CDVInvokedUrlCommand) {
        print("🔵 registerCallback called")
        // Store the callbackId to be used for all future async events.
        self.eventCallbackContext = command.callbackId

        // Send a confirmation event to JS to confirm registration.
        let payload: [String: Any] = [
            "event": "callbackRegistered",
            "data": "Successfully registered for events."
        ]
        
        // Use setKeepCallback(true) to keep this channel open.
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: payload)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: self.eventCallbackContext)
    }

    @objc(startScanning:)
    func startScanning(command: CDVInvokedUrlCommand) {
        print("🔵 startScanning called")
        guard isCallbackRegistered(command.callbackId) else { return }

        if bluetoothManager.state == .poweredOn {
            OmronBluetoothManager.sharedInstance.startScanning()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Scan command issued.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Bluetooth is not enabled.")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(connectAndSync:)
    func connectAndSync(command: CDVInvokedUrlCommand) {
        print("🔵 connectAndSync called")
        guard isCallbackRegistered(command.callbackId) else { return }
        
        OmronBluetoothManager.sharedInstance.connectAndSync()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Connect & Sync command issued.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(disconnect:)
    func disconnect(command: CDVInvokedUrlCommand) {
        print("🔵 disconnect called")
        OmronBluetoothManager.sharedInstance.disconnect()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Device disconnected successfully.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(isBloodPressureDeviceLinked:)
    func isBloodPressureDeviceLinked(command: CDVInvokedUrlCommand) {
        print("🔵 isBloodPressureDeviceLinked called")
        let isLinked = OmronBluetoothManager.sharedInstance.isBloodPressureDevicePresent()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isLinked)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    // This action is removed in the new model. The Android equivalent 'unlink' calls 'disconnect'.
    // If you need a separate 'unpair' functionality, it should be added to the OmronBluetoothManager.
    @objc(unlink:)
    func unlink(command: CDVInvokedUrlCommand) {
        print("🔵 unlink called (executes disconnect)")
        OmronBluetoothManager.sharedInstance.disconnect()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Device unlinked successfully.")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    // MARK: - Event & Error Sending Helper Methods

    // Helper to send structured events to JavaScript.
    private func sendEvent(eventName: String, data: Any) {
        guard let callbackId = self.eventCallbackContext else {
            print("❌ Error: Cannot send event '\(eventName)', callback context is not registered.")
            return
        }
        
        let payload: [String: Any] = ["event": eventName, "data": data]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: payload)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback alive
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    // Helper to send structured errors to JavaScript.
    private func sendError(errorMessage: String) {
        guard let callbackId = self.eventCallbackContext else {
            print("❌ Error: Cannot send error '\(errorMessage)', callback context is not registered.")
            return
        }

        let payload: [String: Any] = ["event": "error", "data": errorMessage]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: payload)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback alive
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }
    
    // Helper to check if the main callback has been set.
    private func isCallbackRegistered(_ commandCallbackId: String) -> Bool {
        if self.eventCallbackContext == nil {
            let errorMessage = "Callback not registered. Call registerCallback() first."
            print("❌ \(errorMessage)")
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: errorMessage)
            self.commandDelegate.send(pluginResult, callbackId: commandCallbackId)
            return false
        }
        return true
    }
}

// MARK: - Omron SDK Delegate Implementation

extension OmronDevicePlugin: OmronBluetoothManagerDelegate {
    
    func didInitialize(isSuccessfully: Bool) {
        print("✅ Omron Delegate: didInitialize -> \(isSuccessfully)")
        // The original `initialize` function now returns immediately.
        // This delegate method sends the actual result through the persistent callback.
        sendEvent(eventName: "initializationComplete", data: ["success": isSuccessfully])
    }

    func didFindDevice(isSuccessfully: Bool) {
        print("✅ Omron Delegate: didFindDevice -> \(isSuccessfully)")
        // NOTE: This delegate seems to only return a boolean. The Android version
        // returns a list of devices. If your OmronBluetoothManager can provide the
        // device list, it should be sent here. For now, this fires a generic event.
        sendEvent(eventName: "scanResult", data: ["foundDevice": isSuccessfully])
    }

    func didConnectDevice(isSuccessfully: Bool, macId: String) {
        print("✅ Omron Delegate: didConnectDevice -> \(isSuccessfully), MAC: \(macId)")
        if isSuccessfully {
            sendEvent(eventName: "connected", data: ["macId": macId, "name": "Omron Blood Pressure Monitor"])
        } else {
            sendError(errorMessage: "Failed to connect to device with MAC ID: \(macId)")
        }
    }

    func didReceiveBloodPressureData(_ data: [String: Any]) {
        print("✅ Omron Delegate: didReceiveBloodPressureData")
        // This is a data event, send it through the persistent callback.
        sendEvent(eventName: "dataSynced", data: data)
    }

    func didDisconnectDevice(isSuccessfully: Bool) {
        print("✅ Omron Delegate: didDisconnectDevice -> \(isSuccessfully)")
        // This is a state change event, send it through the persistent callback.
        sendEvent(eventName: "disconnected", data: "Device disconnected")
    }
}


// MARK: - CoreBluetooth State Delegate

extension OmronDevicePlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // You can use this to send a bluetooth status event to the JS side if needed.
        var stateMessage = ""
        switch central.state {
        case .poweredOn: stateMessage = "poweredOn"; print("🔵 Bluetooth is ON")
        case .poweredOff: stateMessage = "poweredOff"; print("❌ Bluetooth is OFF")
        default: stateMessage = "other"
        }
        sendEvent(eventName: "bluetoothStateChanged", data: stateMessage)
    }
}
