swift
import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(GoqiiPlugin) class GoqiiPlugin: CDVPlugin {
    
    // 1. Single callback for all asynchronous events
    var eventCallbackId: String?
    
    // Plugin state properties
    var bluetoothManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var isNewPairingProcess: Bool = false
    var shouldSyncAllRecords: Bool = false
    var customTimeoutMs: Double = 20000.0 // Default to 20 seconds
    var connectionTimeoutWorkItem: DispatchWorkItem?

    override func pluginInitialize() {
        print("🟢 GoqiiPlugin (Contour) pluginInitialize called")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // Initialize the GlucoBLEManager singleton
        _ = GlucoBLEManager.shared
        // Set the delegate immediately
        GlucoBLEManager.shared.glucoBleManagerDelegate = self
    }

    // MARK: - Event Dispatchers

    /// Sends a success event to the persistent JavaScript callback.
    private func sendEvent(data: [String: Any]) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: eventCallbackId is not set. Cannot send event: \(data["code"] ?? "N/A")")
            return
        }
        let pluginResult = CDVPluginResult(status: .ok, messageAs: data)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback channel open
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    /// Sends an error event to the persistent JavaScript callback.
    private func sendErrorEvent(data: [String: Any]) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: eventCallbackId is not set. Cannot send error event: \(data["code"] ?? "N/A")")
            return
        }
        let pluginResult = CDVPluginResult(status: .error, messageAs: data)
        pluginResult?.setKeepCallbackAs(true) // Keep the callback channel open
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    // MARK: - Cordova Action Handlers

    /// Registers the single persistent callback for all plugin events.
    @objc(registerCallback:)
    func registerCallback(command: CDVInvokedUrlCommand) {
        print("🔵 registerCallback called")
        self.eventCallbackId = command.callbackId
        
        let pluginResult = CDVPluginResult(status: .noResult)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Initializes the SDK and checks Bluetooth status.
    @objc(initializeSDK:)
    func initializeSDK(command: CDVInvokedUrlCommand) {
        print("🟢 initializeSDK called")
        // Delegate is already set in pluginInitialize
        
        let status: CDVCommandStatus
        var result: [String: Any]
        
        switch bluetoothManager.state {
        case .poweredOn:
            status = .ok
            result = ["code": "BLUETOOTH_ON", "msg": "Bluetooth is enabled."]
        case .poweredOff, .unsupported, .unauthorized:
            status = .error
            result = ["code": "BLUETOOTH_OFF", "msg": "Bluetooth is not enabled."]
        default: // .unknown, .resetting
            status = .ok // Acknowledge the call; the final state will be sent as an event
            result = ["code": "BLUETOOTH_INITIALIZING", "msg": "Bluetooth state is initializing."]
        }
        
        let pluginResult = CDVPluginResult(status: status, messageAs: result)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    /// Checks if a glucometer has been previously paired/stored.
    @objc(isDevicePaired:)
    func isDevicePaired(command: CDVInvokedUrlCommand) {
        let isPaired = BLE.sharedInstance().isGlucoMeterConnected()
        let pluginResult = CDVPluginResult(status: .ok, messageAs: isPaired)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Checks the current physical connection state.
    @objc(isDeviceConnected:)
    func isDeviceConnected(command: CDVInvokedUrlCommand) {
        let isConnected = GlucoBLEManager.shared.isCurrentlyConnected()
        let pluginResult = CDVPluginResult(status: .ok, messageAs: isConnected)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Gets the UUID of the stored glucometer.
    @objc(getCurrentDeviceMacId:)
    func getCurrentDeviceMacId(command: CDVInvokedUrlCommand) {
        let macId = GlucoBLEManager.shared.getGlucoUUID()
        let pluginResult = CDVPluginResult(status: .ok, messageAs: macId)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    /// Starts scanning for BLE glucometers.
    @objc(startBGMDiscovery:)
    func startBGMDiscovery(command: CDVInvokedUrlCommand) {
        print("🔍 startBGMDiscovery called")
        guard bluetoothManager.state == .poweredOn else {
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: "Bluetooth is off."), callbackId: command.callbackId)
            sendErrorEvent(data: ["code": "BLUETOOTH_OFF", "msg": "Cannot scan, Bluetooth is not enabled."])
            return
        }
        GlucoBLEManager.shared.startBLE()
        self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Scan started."), callbackId: command.callbackId)
    }
    
    /// Initiates pairing with the most recently discovered peripheral.
    @objc(pairBGM:)
    func pairBGM(command: CDVInvokedUrlCommand) {
        print("🔗 pairBGM called")
        self.isNewPairingProcess = true
        guard let peripheralToConnect = self.peripheral else {
            let errorMsg = "No peripheral found to pair. Please scan first."
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: errorMsg), callbackId: command.callbackId)
            sendErrorEvent(data: ["code": "DEVICE_NOT_FOUND", "msg": errorMsg])
            return
        }
        print("🔗 Connecting to Glucometer: \(peripheralToConnect.name ?? "Unknown")")
        GlucoBLEManager.shared.connect(peripheral: peripheralToConnect)
        self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Pairing process initiated."), callbackId: command.callbackId)
    }

    /// Connects to a previously stored device to sync data.
    @objc(connectToKnownDevice:)
    func connectToKnownDevice(command: CDVInvokedUrlCommand) {
        print("🔄 connectToKnownDevice called")
        self.isNewPairingProcess = false
        GlucoBLEManager.shared.removeprevRequestDevice()

        guard BLE.sharedInstance().isGlucoMeterConnected() else {
            let errorMsg = "No stored device to connect to. Please pair a device first."
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: errorMsg), callbackId: command.callbackId)
            sendErrorEvent(data: ["code": "NO_PAIRED_DEVICE", "msg": errorMsg])
            return
        }
        
        startConnectionTimeout(for: "Sync") { [weak self] in
            self?.sendErrorEvent(data: ["code": "TIMEOUT_EXCEEDED", "msg": "Sync timed out. Please ensure your device is on."])
        }
        
        GlucoBLEManager.shared.connectToSavedGlucometerDevice()
        self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Sync process initiated."), callbackId: command.callbackId)
    }

    /// Unlinks the stored glucometer.
    @objc(unlinkGlucometer:)
    func unlinkGlucometer(command: CDVInvokedUrlCommand) {
        print("🔌 unlinkGlucometer called")
        BLE.sharedInstance().unlinkGlucoMeter()
        UserDefaults.standard.removeObject(forKey: "SyncedGlucoLogDates")
        UserDefaults.standard.synchronize()
        sendEvent(data: ["code": "UNLINK_SUCCESS", "msg": "Device unlinked and sync history cleared."])
        self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Unlink successful."), callbackId: command.callbackId)
    }

    /// Explicitly sets the MAC ID to connect to.
    @objc(setGlucometerMacId:)
    func setGlucometerMacId(command: CDVInvokedUrlCommand) {
        guard let macId = command.argument(at: 0) as? String, !macId.isEmpty else {
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: "Invalid MAC ID provided."), callbackId: command.callbackId)
            return
        }
        GlucoBLEManager.shared.connectAndSaveGlucometerDevice(macId)
        self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Attempting to connect with provided MAC ID."), callbackId: command.callbackId)
    }

    /// Sets a flag to sync all historical records on the next sync.
    @objc(setSyncAllRecords:)
    func setSyncAllRecords(command: CDVInvokedUrlCommand) {
        if let flag = command.argument(at: 0) as? Bool {
            self.shouldSyncAllRecords = flag
            print("⚙️ shouldSyncAllRecords flag set to: \(flag)")
            self.commandDelegate.send(CDVPluginResult(status: .ok, messageAs: "Flag updated."), callbackId: command.callbackId)
        }
    }
    
    // MARK: - Timeout Helpers
    
    private func startConnectionTimeout(for operation: String, onTimeout: @escaping () -> Void) {
        cancelConnectionTimeout()
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
extension GoqiiPlugin: CBCentralManagerDelegate {
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

// MARK: - GlucoBLEManagerProtocol
extension GoqiiPlugin: GlucoBLEManagerProtocol {

    func BLEfoundPeripheral(device: CBPeripheral, rssi: Int, mac: String) {
        print("📡 Found Device: \(device.name ?? "Unknown") | RSSI: \(rssi)")
        self.peripheral = device // Store the most recently found peripheral for the pairBGM action
        
        let deviceInfo: [String: Any] = [
            "code": "ON_DEVICE_FOUND",
            "name": device.name ?? "Unknown",
            "macId": mac,
            "rssi": rssi
        ]
        sendEvent(data: deviceInfo)
    }

    func onPairingSuccess(device: CBPeripheral) {
        print("🔗 onPairingSuccess delegate. Secure bond verified!")
        cancelConnectionTimeout()
        
        sendEvent(data: ["code": "DEVICE_CONNECTED", "state": "connected", "macId": device.identifier.uuidString])

        if self.isNewPairingProcess {
            sendEvent(data: ["code": "ON_PAIRING_SUCCESS", "msg": "Pairing successful", "isSuccessfully": true])
            self.isNewPairingProcess = false
        }
    }

    func onPairingFail(device: CBPeripheral) {
        print("❌ onPairingFail delegate.")
        cancelConnectionTimeout()
        sendErrorEvent(data: ["code": "ON_PAIRING_FAILED", "msg": "Failed to establish a secure bond with the device."])
    }

    func glucoMeterData(_ data: [Any]) {
        print("🩸 glucoMeterData delegate: \(data.count) records. SyncAll=\(self.shouldSyncAllRecords)")
        cancelConnectionTimeout()

        var syncedDates = UserDefaults.standard.stringArray(forKey: "SyncedGlucoLogDates") ?? []
        let syncedDatesSet = Set(syncedDates)
        var newDatesFound = false

        let filteredData = data.compactMap { item -> [String: Any]? in
            guard let dict = item as? [String: Any], let dateString = dict["logDate"] as? String else { return nil }
            
            let isNewRecord = !syncedDatesSet.contains(dateString)
            if isNewRecord {
                syncedDates.append(dateString)
                newDatesFound = true
            }
            return self.shouldSyncAllRecords || isNewRecord ? dict : nil
        }
        
        if newDatesFound {
            UserDefaults.standard.set(syncedDates, forKey: "SyncedGlucoLogDates")
            print("💾 Saved new sync dates. Total unique records stored: \(syncedDates.count)")
        }

        self.shouldSyncAllRecords = false // Reset flag after every sync

        sendEvent(data: ["code": "ON_DATA_RECEIVED", "data": filteredData, "msg": "Glucose data received."])
    }

    func glucoMeterConnectError(errorStr: String) {
        print("❌ glucoMeterConnectError delegate: \(errorStr)")
        cancelConnectionTimeout()
        sendErrorEvent(data: ["code": "DEVICE_CONNECTION_ERROR", "msg": errorStr])
    }
    
    // Other delegate methods can be mapped to events as needed
    func BLEactivated(state: Bool) { print("💡 BLE Activated: \(state)") }
    func BLEready(RACPcharacteristic: CBCharacteristic) { print("✅ BLEready: Ready for RACP.") }
    func BLESyncCompleted() { print("✅ BLESyncCompleted.") }
    func glucoMeterConnected(device: CBPeripheral) { print("🔗 Physical link established, waiting for pairing...") }
}
