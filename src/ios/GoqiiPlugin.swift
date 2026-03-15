import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(GoqiiPlugin) class GoqiiPlugin: CDVPlugin {
    var peripheral: CBPeripheral?
    var initGoqiiGlucometerConnectToStoredCallbackId: String?
    var initializeSDKCallbackId: String?
    var searchCallbackId: String?
    var dataCallbackId: String?
    var bluetoothManager: CBCentralManager!
    var reconnectionTimer: DispatchWorkItem?
    var bluetoothIsOn: Bool = false
    var customTimeoutMs: Double = 10.0
    var connectionStateCallbackId: String?
    var isNewPairingProcess: Bool = false

    var discoveredDevices: [[String: Any]] = []
    var discoveryTimer: DispatchWorkItem?

    var shouldSyncAllRecords: Bool = false
    var isSyncCancelled: Bool = false
    var isSyncCancelledCounter: Int = 0

    override func pluginInitialize() {
        print("🟢 Contour pluginInitialize called...GoqiiPlugin")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        _ = GlucoBLEManager.shared
    }

    
    @objc(initializeSDK:)
        func initializeSDK(command: CDVInvokedUrlCommand) {
            print("🟢 Contour initializeSDK called...GoqiiPlugin")
            self.initializeSDKCallbackId = command.callbackId
            GlucoBLEManager.shared.glucoBleManagerDelegate = self
            
            switch bluetoothManager.state {
            case .poweredOn:
                // Already ON, send success immediately
                let pluginResult = CDVPluginResult(status: .ok, messageAs: [
                    "code": "BLUETOOTH_ON",
                    "msg": "Bluetooth is enabled."
                ])
                pluginResult.setKeepCallbackAs(true)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                
            case .unknown, .resetting:
                // WAIT: Do not send error. Let centralManagerDidUpdateState send the callback when ready.
                print("⏳ Bluetooth is booting up. Waiting for state update...")
                
            case .poweredOff, .unsupported, .unauthorized:
                // Truly disabled or unsupported. Send Standardized Error.
                let pluginResult = CDVPluginResult(status: .error, messageAs: [
                    "code": "BLUETOOTH_OFF",
                    "msg": "Bluetooth is not enabled."
                ])
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                
            @unknown default:
                break
            }
        }

    //mac stored or not
    @objc(isDevicePaired:)
   func isDevicePaired(command: CDVInvokedUrlCommand) {
    print("🟢 Contour isDevicePaired called...GoqiiPlugin")
       _ = GlucoBLEManager.shared
       let isConnected = BLE.sharedInstance().isGlucoMeterConnected()
       
       let pluginResult = CDVPluginResult(status: .ok, messageAs: isConnected)
       self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
   }
   

// currently connected to ble or not
@objc(isDeviceConnected:)
    func isDeviceConnected(command: CDVInvokedUrlCommand) {
        print("🟢 Contour isDeviceConnected called...GoqiiPlugin")
        
        // Ask the intermediate manager for the true physical connection state
        let isCurrentlyConnected = GlucoBLEManager.shared.isCurrentlyConnected()
        
        let pluginResult = CDVPluginResult(status: .ok, messageAs: isCurrentlyConnected)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

// get mac
@objc(getCurrentDeviceMacId:)
func getCurrentDeviceMacId(command: CDVInvokedUrlCommand) {
    print("🔍 getCurrentDeviceMacId called...GoqiiPlugin")
    
    // This safely grabs the MAC ID, or defaults to "" automatically 
    let macId = GlucoBLEManager.shared.getGlucoUUID()
    
    // Directly return the raw string to JavaScript
    let pluginResult = CDVPluginResult(status: .ok, messageAs: macId)
    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
}

@objc(startBGMDiscovery:)
    func startBGMDiscovery(command: CDVInvokedUrlCommand) {
        print("🔍 startBGMDiscovery called...")

        searchCallbackId = command.callbackId

        if bluetoothManager.state != .poweredOn {
            print("⚠️ Bluetooth is OFF. Cannot scan.")
            let pluginResult = CDVPluginResult(status: .error, messageAs: [
                "code": "BLUETOOTH_OFF",
                "msg": "Bluetooth is not enabled."
            ])
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }

        // 1. Clear previous scan results
        self.discoveredDevices.removeAll()

        // 2. Start the BLE Scan
        GlucoBLEManager.shared.startBLE()
        
        GlucoBLEManager.shared.removeprevRequestDevice()

        // 3. Cancel any existing timer just in case
        discoveryTimer?.cancel()
        
        // 4. Create a 10-second timer to aggregate devices
        discoveryTimer = DispatchWorkItem { [weak self] in
            guard let self = self, let callbackId = self.searchCallbackId else { return }
            
            // Stop scanning at the hardware level
            GlucoBLEManager.shared.stopSearch()
            
            if self.discoveredDevices.isEmpty {
                // If the array is empty after 10 seconds, send DEVICE_NOT_FOUND
                print("⚠️ Scan finished. No devices found.")
                let errorResult = CDVPluginResult(status: .error, messageAs: [
                    "code": "DEVICE_NOT_FOUND",
                    "msg": "No Glucometer device was found in the vicinity."
                ])
                self.commandDelegate.send(errorResult, callbackId: callbackId)
            } else {
                // If we found devices, wrap the array exactly like Android does!
                print("✅ Scan finished. Returning \(self.discoveredDevices.count) unique devices.")
                let successPayload: [String: Any] = [
                    "code": "ON_DEVICE_FOUND",
                    "data": self.discoveredDevices,
                    "msg": "Devices Found"
                ]
                
                let pluginResult = CDVPluginResult(status: .ok, messageAs: successPayload)
                pluginResult.setKeepCallbackAs(true)
                self.commandDelegate.send(pluginResult, callbackId: callbackId)
            }
            
            // We do NOT nil the callback ID here, in case the UI needs it for pairing later
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()  + self.customTimeoutMs, execute: discoveryTimer!)
    }


@objc(stopBGMDiscovery:)
    func stopBGMDiscovery(command: CDVInvokedUrlCommand) {
        discoveryTimer?.cancel()
        GlucoBLEManager.shared.stopSearch()
        
        let result = CDVPluginResult(status: .ok, messageAs: [
            "code": "SCAN_STOPPED", 
            "msg": "Glucometer scan explicitly stopped by user."
        ])
        self.commandDelegate.send(result, callbackId: command.callbackId)
}

    @objc(pairBGM:)
    func pairBGM(command: CDVInvokedUrlCommand) {
        print("🔗 pairBGM called...")

        self.isNewPairingProcess = true
        guard let peripheral = self.peripheral else {
            print("⚠️ No glucometer found to connect.")
             let pluginResult = CDVPluginResult(status: .error, messageAs: [
                    "code": "DEVICE_NOT_FOUND",
                    "msg": "No Glucometer device was found in the vicinity."
                ])
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }

        print("🔗 Connecting to Glucometer: \(peripheral.name ?? "Unknown")")
        GlucoBLEManager.shared.connect(peripheral: peripheral)

        // let pluginResult = CDVPluginResult(status: .ok, messageAs: ["code":"MAC_ID","MAC": peripheral.identifier.uuidString,"msg":"Mac is \(peripheral.identifier.uuidString)"])
        // self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

@objc(pairBGMWithId:)
    func pairBGMWithId(command: CDVInvokedUrlCommand) {
        // 1. Extract the specific MAC ID / UUID passed from JavaScript
        guard let targetMacId = command.argument(at: 0) as? String, !targetMacId.isEmpty else {
            let errorResult = CDVPluginResult(status: .error, messageAs: [
                "code": "INVALID_ARGUMENT",
                "msg": "You must provide a MAC ID / UUID to pair."
            ])
            self.commandDelegate.send(errorResult, callbackId: command.callbackId)
            return
        }
        
        print("🔗 Targeted Pairing Initiated for MAC: \(targetMacId)")
        
        // Save the callback ID globally so we can respond when `onPairingSuccessGlucometer` fires
        // Assuming you have a variable like: var pairingCallbackId: String?
        // self.pairingCallbackId = command.callbackId 
        
        // 2. Stop any active scanning to free up the Bluetooth antenna
        GlucoBLEManager.shared.stopSearch()
        
        // 3. Connect directly to the targeted device
        GlucoBLEManager.shared.connectAndSaveGlucometerDevice(targetMacId)
        
        // Optional: If you want to immediately acknowledge the command was received
        // let pluginResult = CDVPluginResult(status: .noResult)
        // pluginResult.setKeepCallbackAs(true)
        // self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    @objc(connectToKnownDevice:)
        func connectToKnownDevice(command: CDVInvokedUrlCommand) {
            print("🔄 connectToKnownDevice called...")
            self.isNewPairingProcess = false
            self.dataCallbackId = command.callbackId
            GlucoBLEManager.shared.removeprevRequestDevice()

            // Standardized Timeout Error
            reconnectionTimer = DispatchWorkItem { [weak self] in
                guard let self = self, let cid = self.dataCallbackId else { return }
                let result = CDVPluginResult(status: .error, messageAs: [
                    "code": "TIMEOUT_EXCEEDED",
                    "msg": "We did not receive a response. Please ensure your device is on and try again."
                ])
                self.commandDelegate.send(result, callbackId: cid)
            }
            
            if BLE.sharedInstance().isGlucoMeterConnected() {
                GlucoBLEManager.shared.connectToSavedGlucometerDevice()
                
                // Use the dynamic custom timeout
                if let timer = reconnectionTimer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.customTimeoutMs, execute: timer)
                }
            } else {
                let pluginResult = CDVPluginResult(status: .error, messageAs: [
                    "code": "MAC_NOT_AVAILABLE",
                    "msg": "GlucoMeter not connected. Ensure it is paired."
                ])
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    

    @objc(stopSync:)
    func stopSync(command: CDVInvokedUrlCommand) {
        // 1. Flip the flag to ignore incoming data
        self.isSyncCancelled = true 
        self.isSyncCancelledCounter = 0 // Reset the counter for the next sync session
        
        print("🛑 Sync cancelled via software. Device remains physically connected.")
        
        let result = CDVPluginResult(status: .ok, messageAs: [
            "code": "SYNC_STOPPED", 
            "msg": "Synchronization cancelled safely without dropping connection."
        ])
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(unlinkGlucometer:)
    func unlinkGlucometer(command: CDVInvokedUrlCommand) {
        print("🔌 unlinkGlucometer called...")

        BLE.sharedInstance().unlinkGlucoMeter()

        UserDefaults.standard.removeObject(forKey: "SyncedGlucoLogDates")
        UserDefaults.standard.synchronize() // Force the save immediately
        print("🗑️ Cleared all synced Glucometer log dates from memory.")

        let pluginResult = CDVPluginResult(status: .ok, messageAs: ["code": "UNLINK","msg":"Unlink Glucometer"])
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }


      @objc(setGlucometerMacId:)
    func setGlucometerMacId(command: CDVInvokedUrlCommand) {
        guard let macId = command.argument(at: 0) as? String, !macId.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: ["code":"MAC_NOT_VALID","msg":"Invalid MAC ID"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        GlucoBLEManager.shared.connectAndSaveGlucometerDevice(macId)
        
        print("✅ Recived MAC ID: \(macId)")

        let result = CDVPluginResult(status: .ok, messageAs: ["code":"MAC_VALID","msg":"MAC ID Recived and trying to connect"])
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(setConnectionTimeout:)
        func setConnectionTimeout(command: CDVInvokedUrlCommand) {
            if let ms = command.argument(at: 0) as? Int {
                self.customTimeoutMs = Double(ms) / 1000.0
                print("⏱️ Glucometer Timeout set to: \(self.customTimeoutMs)s")
                let result = CDVPluginResult(status: .ok, messageAs: ["code": "TIMEOUT_TIME_UPDATED","msg":"Timeout time updated"])
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }

        @objc(deviceConnectionState:)
        func deviceConnectionState(command: CDVInvokedUrlCommand) {
            print("📡 Glucometer deviceConnectionState listener registered")
            self.connectionStateCallbackId = command.callbackId
        }

   
    @objc(setLiveReadingDelay:)
    func setLiveReadingDelay(command: CDVInvokedUrlCommand) {
        // Get ms from JS arguments
        if let ms = command.argument(at: 0) as? Int {
            // Convert to seconds for the Swift timer
            let delaySeconds = Double(ms) / 1000.0
            
            // ✨ Call the newly renamed Manager function!
            GlucoBLEManager.shared.updateLiveReadingDelay(seconds: delaySeconds)
            
            print("⏱️ Plugin Live Reading Delay set to: \(delaySeconds)s")
            
            let result = CDVPluginResult(status: .ok, messageAs: [
                "code": "LIVE_READING_DELAY_UPDATED",
                "msg": "Live reading delay updated to \(delaySeconds)s"
            ])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            
        } else {
            // Fallback if JavaScript forgets to pass the argument
            let result = CDVPluginResult(status: .error, messageAs: [
                "code": "INVALID_ARGUMENT",
                "msg": "Please provide the delay in milliseconds."
            ])
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }
    
}

// MARK: - Bluetooth Delegate
extension GoqiiPlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is ON GoqiiPlugin")
            // If initializeSDK was waiting for this, send success now!
            if let callbackId = self.initializeSDKCallbackId {
                let pluginResult = CDVPluginResult(status: .ok, messageAs: [
                    "code": "BLUETOOTH_ON",
                    "msg": "Bluetooth is enabled."
                ])
                pluginResult.setKeepCallbackAs(true)
                self.commandDelegate!.send(pluginResult, callbackId: callbackId)
            }
        case .poweredOff:
            print("❌ Bluetooth is OFF GoqiiPlugin")
            if let callbackId = self.initializeSDKCallbackId {
                let pluginResult = CDVPluginResult(status: .error, messageAs: [
                    "code": "BLUETOOTH_OFF",
                    "msg": "Bluetooth is not enabled."
                ])
                self.commandDelegate!.send(pluginResult, callbackId: callbackId)
            }
        case .resetting:
            print("🔄 Bluetooth is resetting GoqiiPlugin")
        case .unauthorized:
            print("⚠️ Bluetooth is not authorized GoqiiPlugin")
        case .unsupported:
            print("❌ Device does not support Bluetooth GoqiiPlugin")
        case .unknown:
            print("🤷 Bluetooth state is unknown GoqiiPlugin")
        @unknown default:
            print("⚠️ Unknown Bluetooth state GoqiiPlugin")
        }
    }
}

// MARK: - Glucometer BLE Delegate
extension GoqiiPlugin: GlucoBLEManagerProtocol {
func BLEactivated(state: Bool) {
    print("💡 BLE Activated: \(state)")

    if state {
        GlucoBLEManager.shared.startScanning()
    }

}

func onPairingFailGlucometer(device: CBPeripheral){
    print("🔗 onPairingFailGlucometer triggered in GoqiiPlugin")
    
      // Use connectCallbackId (or fallback to searchCallbackId)
        if let callbackId = dataCallbackId ?? searchCallbackId {
            let result: [String: Any] = [
                "code": "ON_PAIRING_FAIL",
                "msg": "On pairing fail"
            ]
            
            let pluginResult = CDVPluginResult(status: .ok, messageAs: result)
            pluginResult.setKeepCallbackAs(true) 
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
            
            print("✅ Sent ON_PAIRING_FAIL to JavaScript.")
        } else {
            print("⚠️ No callback ID found to send pairing success.")
        }
}

func BLEfoundPeripheral(device: CBPeripheral, rssi: Int, mac: String, advData: [String: Any]) {
        print("📡 Found Device: \(device.name ?? "Unknown") | RSSI: \(rssi) | MAC: \(mac)")

        let connectedMACID = GlucoBLEManager.shared.getGlucoUUID()
        print("🔗 Previously Connected MAC: \(connectedMACID)")

        // --- Keep your existing logic for auto-assigning known peripherals ---
        if self.peripheral == nil {
            print("ℹ️ No previously assigned peripheral.")
        } else {
            print("✔️ A peripheral was already assigned.")
        }

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

        let isDuplicate = self.discoveredDevices.contains { existingDevice in
            if let existingMac = existingDevice["id"] as? String {
                return existingMac == mac
            }
            return false
        }
        
        if !isDuplicate {
            // Create the dictionary exactly matching the required structure
            let deviceInfo: [String: Any] = [
                "name": device.name ?? "Unknown",
                "id": mac,
                "deviceType": "Glucometer",
                "rssi": rssi,
                "advData" : advData
            ]
            
            self.discoveredDevices.append(deviceInfo)
            print("📥 Added \(device.name ?? "Unknown") to discovery array. Total: \(self.discoveredDevices.count)")
        }
    }

    func BLEready(RACPcharacteristic: CBCharacteristic) {
        print("✅ BLEready Glucometer is ready for data sync. Ensure device is paired.")
    }



func glucoMeterConnected(device: CBPeripheral) {
       print("🟢 SDK glucoMeterConnected: Physical link established!")
        self.peripheral = device
        
        // Do NOT send "connected" yet! Just tell the app we are establishing a link.
        // if let stateId = connectionStateCallbackId {
        //     let deviceInfo = [
        //         "code": "DEVICE_CONNECTING",
        //         "state": "connecting", 
        //         "msg": "Physical link established, waiting for secure pairing..."
        //     ]
        //     let pluginResult = CDVPluginResult(status: .ok, messageAs: deviceInfo)
        //     pluginResult.setKeepCallbackAs(true)
        //     self.commandDelegate.send(pluginResult, callbackId: stateId)
        // }
    }



func glucoMeterDisconnected() {
        print("🔴 SDK glucoMeterDisconnected: Physical link dropped.")
        
        // Notify the continuous state listener that the device disconnected
        if let stateId = connectionStateCallbackId {
            let stateInfo: [String: Any] = [
                "code": "DEVICE_DISCONNECTED",
                "state": "disconnected",
                "msg": "Device physically disconnected."
            ]
            let stateResult = CDVPluginResult(status: .ok, messageAs: stateInfo)
            
            // CRITICAL: Keep callback true so it stays alive for the next connection!
            stateResult.setKeepCallbackAs(true) 
            self.commandDelegate.send(stateResult, callbackId: stateId)
        }
    }
    
    func onPairingSuccessGlucometer(device: CBPeripheral) {
        print("🔗 onPairingSuccessGlucometer triggered. Secure bond verified!")
        
        // A. Send DEVICE_CONNECTED to the State Listener (Turns the dot Green!)
        if let stateId = connectionStateCallbackId {
            let stateInfo = ["code": "DEVICE_CONNECTED","state": "connected", "msg": "Device connected", "macId": "\(device.identifier.uuidString)", "MacId": "\(device.identifier.uuidString)"]
            let stateResult = CDVPluginResult(status: .ok, messageAs: stateInfo)
            stateResult.setKeepCallbackAs(true)
            self.commandDelegate.send(stateResult, callbackId: stateId)
        }

        // B. Send ON_PAIRING_SUCCESS to the Action Callback (Shows the alert popup)
        // ONLY if they actually clicked the "Pair Device" button
        if self.isNewPairingProcess {
            if let callbackId = searchCallbackId ?? dataCallbackId {
                let actionInfo: [String: Any] = [
                    "code": "ON_PAIRING_SUCCESS",
                    "msg": "Pairing successful",
                    "isSuccessfully": true
                ]
                let actionResult = CDVPluginResult(status: .ok, messageAs: actionInfo)
                actionResult.setKeepCallbackAs(true)
                self.commandDelegate.send(actionResult, callbackId: callbackId)
            }
            self.isNewPairingProcess = false
        }
    }

@objc(setSyncAllRecords:)
    func setSyncAllRecords(command: CDVInvokedUrlCommand) {
        if let flag = command.argument(at: 0) as? Bool {
            self.shouldSyncAllRecords = flag
            print("⚙️ setSyncAllRecords flag updated to: \(flag)")
            
            let pluginResult = CDVPluginResult(status: .ok, messageAs: ["code": "FLAG_UPDATED", "msg": "Sync all records set to \(flag)"])
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

func glucoMeterData(_ data: [Any]) {
        reconnectionTimer?.cancel()
        print("📊 Received Glucometer Data Batch: \(data.count) records. Sync All Flag: \(self.shouldSyncAllRecords)")

        if self.isSyncCancelled && self.isSyncCancelledCounter == 1 {
            print("🛑 Ignoring \(data.count) records because the sync was cancelled by the user.")
            self.isSyncCancelled = false // Reset the flag so future live readings still work!
            self.isSyncCancelledCounter = 0 // Reset the counter for the next sync session
            return // Exit immediately, do not send to JS!
        }else if self.isSyncCancelled {
            print("⚠️ Received data but sync is cancelled. Counter: \(self.isSyncCancelledCounter). Will ignore this batch but keep counting.")
            self.isSyncCancelledCounter += 1
            return
        }

        guard let callbackId = dataCallbackId ?? initGoqiiGlucometerConnectToStoredCallbackId else { return }

        // 1. Fetch the array of all previously synced logDates (Defaults to empty array for first-time users)
        var syncedDates = UserDefaults.standard.stringArray(forKey: "SyncedGlucoLogDates") ?? [String]()
        
        // Convert to a Set for lightning-fast lookups (O(1) performance)
        var syncedDatesSet = Set(syncedDates)
        var newlyDiscoveredDates = false

        // 2. Filter data
        let filteredData = data.compactMap { item -> [String: Any]? in
            guard let dict = item as? [String: Any],
                  let dateString = dict["logDate"] as? String else {
                return nil
            }

            let isAlreadySynced = syncedDatesSet.contains(dateString)

            // If we have never seen this exact timestamp before, track it!
            if !isAlreadySynced {
                syncedDatesSet.insert(dateString)
                syncedDates.append(dateString)
                newlyDiscoveredDates = true
            }

            // Return if the JS flag says "Sync All", OR if it's a newly discovered record
            if self.shouldSyncAllRecords {
                return dict
            } else {
                return isAlreadySynced ? nil : dict
            }
        }

        // 3. Save the updated list of dates back to UserDefaults ONLY if we found new ones
        if newlyDiscoveredDates {
            UserDefaults.standard.set(syncedDates, forKey: "SyncedGlucoLogDates")
            UserDefaults.standard.synchronize() 
            print("💾 Saved new synced dates. Total unique records stored in memory: \(syncedDates.count)")
        }

        // SAFETY RESET: Reset the flag to false so the next auto-sync defaults back to "New Only"
        self.shouldSyncAllRecords = false

        // ✨ THE ACCU-CHEK FIX: Force Cordova to serialize this strictly as a JSON Array!
        // If it's empty, we pass an explicit `[]` so it never becomes `{}`.
        let finalDataArray: [[String: Any]] = filteredData.isEmpty ? [] : filteredData

        // 4. Send back to JS
        let payload: [String: Any] = [
            "code": "ON_DATA_RECEIVED",
            "data": finalDataArray,
            "msg": "Glucose Data Received Successfully!"
        ]
        
        let pluginResult = CDVPluginResult(status: .ok, messageAs: payload)
        pluginResult.setKeepCallbackAs(true)
        self.commandDelegate!.send(pluginResult, callbackId: callbackId)
    }


func BLESyncCompleted() {
        print("✅ Glucometer Data Sync Completed.")
    }
    
    
func glucoMeterConnectError(errorStr: String) {
        print("glucoMeterConnectError in plugin = \(errorStr)")

         guard let callbackId = self.initGoqiiGlucometerConnectToStoredCallbackId else {
        print("⚠️ No callbackId stored")
        return
        }

            let pluginResult = CDVPluginResult(status: .error, messageAs: [
                "code": "DEVICE_CONNECTION_ERROR",
                "msg": "Device is connection error."
            ])
        pluginResult.setKeepCallbackAs(true)
    self.commandDelegate?.send(pluginResult, callbackId: callbackId)
    }
}
