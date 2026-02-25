import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(GoqiiPlugin) class GoqiiPlugin: CDVPlugin {
    var peripheral: CBPeripheral?
    var initGoqiiGlucometerSettingsCallbackId: String?
    var initializeSDKCallbackId: String?
    var searchCallbackId: String?
    var dataCallbackId: String?
    var bluetoothManager: CBCentralManager!

    override func pluginInitialize() {
        print("GoqiiPlugin pluginInitialize")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        
    }

    @objc(initGoqiiGlucometerSettings:)
    func initGoqiiGlucometerSettings(command: CDVInvokedUrlCommand) {
    print("initGoqiiGlucometerSettings")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        initGoqiiGlucometerSettingsCallbackId = command.callbackId
        if BLE.sharedInstance().isGlucoMeterConnected() {
            print("✅ GlucoMeter is connected, starting sync... via initGoqiiGlucometerSettings")
            GlucoBLEManager.shared.glucoBleManagerDelegate = self
            GlucoBLEManager.shared.connectToSavedGlucometerDevice()
            
        }
    }

    @objc(initializeSDK:)
    func initializeSDK(command: CDVInvokedUrlCommand) {
        print("🟢 initializeSDK called... isGlucoMeterConnected = \(BLE.sharedInstance().isGlucoMeterConnected())")

        initializeSDKCallbackId = command.callbackId
        GlucoBLEManager.shared.glucoBleManagerDelegate = self

        var pluginResult: CDVPluginResult
        if bluetoothManager.state == .poweredOn {
            var connectedMACID = ""
            if BLE.sharedInstance().isGlucoMeterConnected() {
                 connectedMACID = GlucoBLEManager.shared.getGlucoUUID()
            }
            
            pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "SDK initialized with Bluetooth ON","glucometerMac":connectedMACID])
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            
        } else {
           // pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: ["data":"Bluetooth is OFF. Please enable Bluetooth."])
        }

        
    }

@objc(searchGlucometer:)
func searchGlucometer(command: CDVInvokedUrlCommand) {
    print("🔍 searchGlucometer called...")

    searchCallbackId = command.callbackId

    if bluetoothManager.state != .poweredOn {
        print("⚠️ Bluetooth is OFF. Cannot scan.")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: ["data":"Bluetooth is OFF"])
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        return
    }

    print("🚀 Starting BLE scan")
    GlucoBLEManager.shared.startBLE()

    let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "Searching for Glucometers..."])
        pluginResult?.setKeepCallbackAs(true)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    
}


    @objc(connectGlucometer:)
    func connectGlucometer(command: CDVInvokedUrlCommand) {
        print("🔗 connectGlucometer called...")

        guard let peripheral = self.peripheral else {
            print("⚠️ No glucometer found to connect.")
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: ["data":"No glucometer found to connect."])
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            return
        }

        print("🔗 Connecting to Glucometer: \(peripheral.name ?? "Unknown")")
        GlucoBLEManager.shared.connect(peripheral: peripheral)

        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "Connect Glucometer started, mac = \(peripheral.identifier.uuidString)"])
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(syncGlucometer:)
    func syncGlucometer(command: CDVInvokedUrlCommand) {
        print("🔄 syncGlucometer called...")

        GlucoBLEManager.shared.glucoBleManagerDelegate = self
        dataCallbackId = command.callbackId
        GlucoBLEManager.shared.removeprevRequestDevice()
        
        if BLE.sharedInstance().isGlucoMeterConnected() {
            print("✅ GlucoMeter is connected, starting sync...")
            GlucoBLEManager.shared.connectToSavedGlucometerDevice()

            // let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["data": "Sync Glucometer started"])
            // self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)

        } else {
            print("❌ GlucoMeter not connected. Ensure it is paired.")
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: ["error":"GlucoMeter not connected. Ensure it is paired to fetch data."])
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(unlinkGlucometer:)
    func unlinkGlucometer(command: CDVInvokedUrlCommand) {
        print("🔌 unlinkGlucometer called...")

        BLE.sharedInstance().unlinkGlucoMeter()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "Unlink Glucometer started"])
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

          @objc(isGlucometerLinked:)
    func isGlucometerLinked(command: CDVInvokedUrlCommand) {
        
        let isConnected = BLE.sharedInstance().isGlucoMeterConnected()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isConnected)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

      @objc(setGlucometerMacId:)
    func setGlucometerMacId(command: CDVInvokedUrlCommand) {
        guard let macId = command.argument(at: 0) as? String, !macId.isEmpty else {
            let result = CDVPluginResult(status: .error, messageAs: ["error":"Invalid MAC ID"])
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        GlucoBLEManager.shared.connectAndSaveGlucometerDevice(macId)
        
        print("✅ Recived MAC ID: \(macId)")

        let result = CDVPluginResult(status: .ok, messageAs: ["data":"MAC ID Recived and trying to connect"])
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

}

// MARK: - Bluetooth Delegate
extension GoqiiPlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
         switch central.state {
         case .poweredOn:
             print("✅ Bluetooth is ON GoqiiPlugin")
         case .poweredOff:
             print("❌ Bluetooth is OFF GoqiiPlugin")
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

    if state { GlucoBLEManager.shared.startScanning() }

    if let callbackId = initializeSDKCallbackId {
        let deviceInfo = ["BLEState": "\(state)"]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: deviceInfo)
            pluginResult??.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        
    }
}


func BLEfoundPeripheral(device: CBPeripheral, rssi: Int, mac: String) {
    print("📡 Found Device: \(device.name ?? "Unknown") | RSSI: \(rssi) | MAC: \(mac)")

    let connectedMACID = GlucoBLEManager.shared.getGlucoUUID()
    print("🔗 Previously Connected MAC: \(connectedMACID)")

    // Check if a device is already assigned
    if self.peripheral == nil {
        print("ℹ️ No previously assigned peripheral.")
    } else {
        print("✔️ A peripheral was already assigned.")
    }

    // Check if a device is already connected
    if BLE.sharedInstance().isGlucoMeterConnected() {
        print("✅ A GlucoMeter is already connected.")
    } else {
        print("❌ No GlucoMeter is currently connected.")
    }

    // Assign the peripheral if it is not set, and the connected MAC matches
    if self.peripheral == nil, 
       BLE.sharedInstance().isGlucoMeterConnected(), 
       connectedMACID == mac {
        self.peripheral = device
        print("🔄 Assigned new peripheral as it matches previous connection.")
        
        if let tempPer = self.peripheral{
        GlucoBLEManager.shared.connect(peripheral: tempPer)
        }
        
    } else {
        self.peripheral = device
        if device.state == .disconnected,BLE.sharedInstance().isGlucoMeterConnected(), connectedMACID == mac {
            print("🔄 Assigned new peripheral as it matches previous connection. 222")
            if let tempPer = self.peripheral{
            GlucoBLEManager.shared.connect(peripheral: tempPer)
            }
        }
        
        print("🔄 Assigned the found peripheral.")
    }

    // Send response if searchCallbackId is available
    if let callbackId = searchCallbackId {
        print("💡 Responding to search callback...")
        searchCallbackId = nil
        let deviceInfo: [String: String] = [
            "name": device.name ?? "Unknown",
            "macId": mac,
            "rssi": "\(rssi)"
        ]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: deviceInfo)
            pluginResult?.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        
    }
}

    func BLEready(RACPcharacteristic: CBCharacteristic) {
        print("✅ BLEready Glucometer is ready for data sync. Ensure device is paired.")
    }

    func glucoMeterConnected(device: CBPeripheral) {
        print("SDK glucoMeterConnected.")
        self.peripheral = device
    }

func glucoMeterData(_ data: [Any]) {
    print("📊 Received Glucometer Data: \(data)")

    if let callbackId = dataCallbackId {
        print("💡 Sending data callback with dataCallbackId")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "\(data)"])
            pluginResult?.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        
    }else if let callbackId = initGoqiiGlucometerSettingsCallbackId{
        print("💡 Sending data callback with initGoqiiGlucometerSettingsCallbackId")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: ["data": "\(data)"])
            pluginResult?.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        
    }
}

    func BLESyncCompleted() {
        print("✅ Glucometer Data Sync Completed.")
    }
    
    func glucoMeterConnectError(errorStr: String) {
        print("glucoMeterConnectError in plugin = \(errorStr)")

         guard let callbackId = self.initGoqiiGlucometerSettingsCallbackId else {
        print("⚠️ No callbackId stored")
        return
        }

    let result = CDVPluginResult(status: .error, messageAs: ["error":errorStr])
    result?.setKeepCallbackAs(true) // Optional: Keep the callback active
    self.commandDelegate?.send(result, callbackId: callbackId)
    }
}
