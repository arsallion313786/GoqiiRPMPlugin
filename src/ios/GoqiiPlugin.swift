import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(GoqiiPlugin) class GoqiiPlugin: CDVPlugin {
    
    // 1. Your single persistent callback for all async events
    var eventCallbackId: String?
    
    // SDK and State Properties
    var bluetoothManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var reconnectionTimer: DispatchWorkItem?
    var discoveryTimer: DispatchWorkItem?
    
    var discoveredDevices: [[String: Any]] = []
    var customTimeoutMs: Double = 10.0
    var pollingTime: Double = 15000.0 // millisec
    var isNewPairingProcess: Bool = false
    var shouldSyncAllRecords: Bool = false
    var isSyncCancelled: Bool = false
    var isSyncCancelledCounter: Int = 0
    var isStopeedSilentPolling: Bool = true

    override func pluginInitialize() {
        print("🟢 GoqiiPlugin (New SDK) pluginInitialize called")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        _ = GlucoBLEManager.shared
        
    }

    // MARK: - Event Dispatchers (Your Core Architecture)

    private func sendEvent(code: String, msg: String, data: Any? = nil) {
        guard let callbackId = self.eventCallbackId else {
            print("⚠️ ERROR: eventCallbackId not set for: \(code)")
            return
        }
        var payload: [String: Any] = ["code": code, "msg": msg]
        if let extraData = data { payload["data"] = extraData }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: payload)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    private func sendErrorEvent(code: String, msg: String) {
        guard let callbackId = self.eventCallbackId else { return }
        let payload: [String: Any] = ["code": code, "msg": msg]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: payload)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: callbackId)
    }

    // MARK: - Cordova Actions

    @objc(registerCallback:)
    func registerCallback(command: CDVInvokedUrlCommand) {
        self.eventCallbackId = command.callbackId
        let pluginResult = CDVPluginResult(status: .noResult)
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        print("🔵 Persistent Callback Registered")
    }

    @objc(initializeSDK:)
    func initializeSDK(command: CDVInvokedUrlCommand) {
        // Just an ACK for the command; results flow through centralManagerDidUpdateState
        GlucoBLEManager.shared.glucoBleManagerDelegate = self
        let result = CDVPluginResult(status: CDVCommandStatus.ok)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(startBGMDiscovery:)
    func startBGMDiscovery(command: CDVInvokedUrlCommand) {
        if bluetoothManager.state != .poweredOn {
            sendErrorEvent(code: "BLUETOOTH_OFF", msg: "Bluetooth is not enabled.")
            return
        }

        self.discoveredDevices.removeAll()
        GlucoBLEManager.shared.startBLE()
        GlucoBLEManager.shared.removeprevRequestDevice()

        discoveryTimer?.cancel()
        discoveryTimer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            GlucoBLEManager.shared.stopSearch()
            
            if self.discoveredDevices.isEmpty {
                self.sendEvent(code: "DEVICE_NOT_FOUND", msg: "No devices found.", data:[])
            } else {
                self.sendEvent(code: "ON_DEVICE_FOUND", msg: "Devices Found", data: self.discoveredDevices)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.customTimeoutMs, execute: discoveryTimer!)
        
        let result = CDVPluginResult(status: CDVCommandStatus.ok)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(pairBGMWithId:)
    func pairBGMWithId(command: CDVInvokedUrlCommand) {
        
        let targetMacId = command.argument(at: 0) as? String
        
//        guard let targetMacId = command.argument(at: 0) as? String, !targetMacId.isEmpty else {
//            let error = CDVPluginResult(status: CDVCommandStatus.error, messageAsString: "Missing MAC ID")
//            self.commandDelegate.send(error, callbackId: command.callbackId)
//            return
//        }
        
        self.isNewPairingProcess = true
        GlucoBLEManager.shared.stopSearch()
        GlucoBLEManager.shared.connectAndSaveGlucometerDevice(targetMacId ?? "")
        
        let result = CDVPluginResult(status: CDVCommandStatus.ok)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(connectToKnownDevice:)
    func connectToKnownDevice(command: CDVInvokedUrlCommand) {
        self.isNewPairingProcess = false
        GlucoBLEManager.shared.removeprevRequestDevice()

        reconnectionTimer?.cancel()
        reconnectionTimer = DispatchWorkItem { [weak self] in
            self?.sendErrorEvent(code: "TIMEOUT_EXCEEDED", msg: "Connection timed out.")
        }
        
        if BLE.sharedInstance().isGlucoMeterConnected() {
            GlucoBLEManager.shared.connectToSavedGlucometerDevice()
            DispatchQueue.main.asyncAfter(deadline: .now() + self.customTimeoutMs, execute: reconnectionTimer!)
        } else {
            let error = CDVPluginResult(status: CDVCommandStatus.error, messageAs: ["code": "MAC_NOT_AVAILABLE"])
            self.commandDelegate.send(error, callbackId: command.callbackId)
        }
    }

    @objc(unlinkGlucometer:)
    func unlinkGlucometer(command: CDVInvokedUrlCommand) {
        BLE.sharedInstance().unlinkGlucoMeter()
        UserDefaults.standard.removeObject(forKey: "SyncedGlucoLogDates")
        UserDefaults.standard.synchronize()
        
        let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["code": "UNLINK"])
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(stopBGMDiscovery:)
        func stopBGMDiscovery(command: CDVInvokedUrlCommand) {
            discoveryTimer?.cancel()
            GlucoBLEManager.shared.stopSearch()
            
            let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: [
                "code": "SCAN_STOPPED",
                "msg": "Glucometer scan explicitly stopped by user."
            ])
            self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(setConnectionTimeout:)
        func setConnectionTimeout(command: CDVInvokedUrlCommand) {
            if let ms = command.argument(at: 0) as? Int {
                self.customTimeoutMs = Double(ms) / 1000.0
                print("⏱️ Glucometer Timeout set to: \(self.customTimeoutMs)s")
                let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["code": "TIMEOUT_TIME_UPDATED","msg":"Timeout time updated"])
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    @objc(isDevicePaired:)
   func isDevicePaired(command: CDVInvokedUrlCommand) {
    print("🟢 Contour isDevicePaired called...GoqiiPlugin")
       _ = GlucoBLEManager.shared
       let isConnected = BLE.sharedInstance().isGlucoMeterConnected()
       
       let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isConnected)
       self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
   }
    
    @objc(isDeviceConnected:)
        func isDeviceConnected(command: CDVInvokedUrlCommand) {
            print("🟢 Contour isDeviceConnected called...GoqiiPlugin")
            
            // Ask the intermediate manager for the true physical connection state
            let isCurrentlyConnected = GlucoBLEManager.shared.isCurrentlyConnected()
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isCurrentlyConnected)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    
    @objc(setSyncAllRecords:)
        func setSyncAllRecords(command: CDVInvokedUrlCommand) {
            if let flag = command.argument(at: 0) as? Bool {
                self.shouldSyncAllRecords = flag
                print("⚙️ setSyncAllRecords flag updated to: \(flag)")
                
                let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["code": "FLAG_UPDATED", "msg": "Sync all records set to \(flag)"])
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    
    @objc(getCurrentDeviceMacId:)
    func getCurrentDeviceMacId(command: CDVInvokedUrlCommand) {
        print("🔍 getCurrentDeviceMacId called...GoqiiPlugin")
        
        
        let macId = GlucoBLEManager.shared.getGlucoUUID()
        
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: macId)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(startSilentBackgroundPolling:)
        func startSilentBackgroundPolling(command: CDVInvokedUrlCommand) {
            print("🔄 JS triggered startSilentBackgroundPolling...")
            self.pollingTime = command.argument(at: 0) as? Double ?? 15000.0 // time is millisec
            
            // 1. Immediately return success to JS so it knows the loop started
            let pluginResult = CDVPluginResult(status: .ok, messageAs: ["code": "POLLING_STARTED", "msg": "Background polling initiated."])
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            
            // 2. Start the native background loop
            self.isStopeedSilentPolling = false;
            self.triggerSilentBackgroundSync()
        }
    
    @objc(stopSilentBackgroundPolling:)
    func stopilentBackgroundPolling(command: CDVInvokedUrlCommand) {
        self.isStopeedSilentPolling = true;
    }
}

// MARK: - Bluetooth & SDK Delegates (Updated to use sendEvent)
extension GoqiiPlugin: CBCentralManagerDelegate, GlucoBLEManagerProtocol {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            sendEvent(code: "BLUETOOTH_ON", msg: "Bluetooth is enabled.")
        } else {
            sendErrorEvent(code: "BLUETOOTH_OFF", msg: "Bluetooth is disabled.")
        }
    }

    func BLEfoundPeripheral(device: CBPeripheral, rssi: Int, mac: String, advData: [String: Any]) {
        let connectedMACID = GlucoBLEManager.shared.getGlucoUUID()
        if self.peripheral == nil,
           BLE.sharedInstance().isGlucoMeterConnected(),
           connectedMACID == mac {
            self.peripheral = device
            print("🔄 Assigned new peripheral as it matches previous connection.")
            if let tempPer = self.peripheral {
                GlucoBLEManager.shared.connect(peripheral: tempPer)
            }
        } else {
            self.peripheral = device
            if device.state == .disconnected, BLE.sharedInstance().isGlucoMeterConnected(), connectedMACID == mac {
                print("🔄 Assigned new peripheral as it matches previous connection. 222")
                if let tempPer = self.peripheral {
                    GlucoBLEManager.shared.connect(peripheral: tempPer)
                }
            }
            print("🔄 Assigned the found peripheral.")
        }

        
        let isDuplicate = self.discoveredDevices.contains { ($0["id"] as? String) == mac }
        if !isDuplicate {
            let deviceInfo: [String: Any] = [
                "name": device.name ?? "Unknown",
                "id": mac,
                "deviceType": "Glucometer",
                "rssi": rssi
            ]
            self.discoveredDevices.append(deviceInfo)
        }
    }

    func onPairingSuccessGlucometer(device: CBPeripheral) {
        // 1. Notify persistent state (The "Green Dot")
        sendEvent(code: "DEVICE_CONNECTED", msg: "Connected", data: ["macId": device.identifier.uuidString])

        // 2. Notify the specific pairing action if active
        if self.isNewPairingProcess {
            sendEvent(code: "ON_PAIRING_SUCCESS", msg: "Pairing successful", data: ["isSuccessfully": true])
            self.isNewPairingProcess = false
        }
    }

    func glucoMeterDisconnected() {
        sendEvent(code: "DEVICE_DISCONNECTED", msg: "Device physically disconnected.", data: ["state": "disconnected"])
    }

    func glucoMeterData(_ data: [Any]) {
         reconnectionTimer?.cancel()
        
         if self.isSyncCancelled {
             self.isSyncCancelled = false
             return
         }

         // Filter and Deduplicate logic
         var syncedDates = UserDefaults.standard.stringArray(forKey: "SyncedGlucoLogDates") ?? []
         let filtered = data.compactMap { item -> [String: Any]? in
             guard let dict = item as? [String: Any], let date = dict["logDate"] as? String else { return nil }
             if !syncedDates.contains(date) {
                 syncedDates.append(date)
                 return dict
             }
             return nil
         }

         if !filtered.isEmpty {
             UserDefaults.standard.set(syncedDates, forKey: "SyncedGlucoLogDates")
             sendEvent(code: "ON_DATA_RECEIVED", msg: "Glucose Data Received", data: filtered)
         }
    }
    
    func BLEactivated(state: Bool) {
            print("💡 BLE Activated: \(state)")
            if state {
                GlucoBLEManager.shared.startScanning()
            }
        }
    func BLEready(RACPcharacteristic: CBCharacteristic) {}
    func glucoMeterConnected(device: CBPeripheral) {
          self.peripheral = device;
          print("🔗 Physical link established, waiting for pairing...")
      }
    func BLESyncCompleted() {}
    func onPairingFailGlucometer(device: CBPeripheral) {
        sendErrorEvent(code: "ON_PAIRING_FAIL", msg: "Pairing failed.")
    }
    func glucoMeterConnectError(errorStr: String) {
        sendErrorEvent(code: "DEVICE_CONNECTION_ERROR", msg: errorStr)
    }
}


extension GoqiiPlugin {
    func triggerSilentBackgroundSync() {
        
        GlucoBLEManager.shared.removeprevRequestDevice()
        
        // 1. SAFETY EXIT: If the user turns off the device, stop the loop instantly so we don't drain the phone's battery!
        guard BLE.sharedInstance().isGlucoMeterConnected() && self.isStopeedSilentPolling == false else {
            self.isStopeedSilentPolling = true
            self.sendEvent(code: "POLLING_STOPPED", msg: "Background polling Cancelled.")
            return
        }
        
        print("🔄 Device is still physically connected. Silently asking for new blood sugar readings...")
        
        // 2. Ask the hardware for data
        GlucoBLEManager.shared.connectToSavedGlucometerDevice()
        
        // 3. Queue up the next silent check (e.g., check again in 15 seconds)
        // This creates a safe loop that only exists in native memory, far away from Cordova!
        DispatchQueue.main.asyncAfter(deadline: .now() + self.pollingTime/1000.0) { [weak self] in
            self?.triggerSilentBackgroundSync()
        }
    }

}

