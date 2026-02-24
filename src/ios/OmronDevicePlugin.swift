import Foundation
import GOQiiSDK
import CoreBluetooth

@objc(OmronDevicePlugin) class OmronDevicePlugin: CDVPlugin {
    var peripheral: CBPeripheral?
    var initializeCallbackId: String?
    var searchCallbackId: String?
    var connectAndSyncCallbackId: String?
    var unlinkCallbackId: String?
    var dataCallbackId: String?
    var bluetoothManager: CBCentralManager!

    override func pluginInitialize() {
        print("🟢 pluginInitialize called...")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        OmronBluetoothManager.sharedInstance.initaliseBle()
    }

    @objc(initOmronDeviceSettings:)
    func initOmronDeviceSettings(command: CDVInvokedUrlCommand) {
        print("initOmronDeviceSettings")
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        OmronBluetoothManager.sharedInstance.initaliseBle()
    }

    @objc(initialize:)
    func initialize(command: CDVInvokedUrlCommand) {
        print("🟢 initialize called...")

        initializeCallbackId = command.callbackId
        OmronBluetoothManager.sharedInstance.initaliseBle()
        OmronBluetoothManager.sharedInstance.delegate = self
    }

    @objc(startScanning:)
    func startScanning(command: CDVInvokedUrlCommand) {
        print("🔍 startScanning called...")
        searchCallbackId = command.callbackId
        if bluetoothManager.state == .poweredOn {
            OmronBluetoothManager.sharedInstance.startScanning()
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Bluetooth is not enabled.")
            self.commandDelegate!.send(pluginResult, callbackId: searchCallbackId!)
        }
    }

    @objc(connectAndSync:)
    func connectAndSync(command: CDVInvokedUrlCommand) {
        print("🔗 connectAndSync called...")
        connectAndSyncCallbackId = command.callbackId
        OmronBluetoothManager.sharedInstance.connectAndSync()
    }

    @objc(unlink:)
    func unlink(command: CDVInvokedUrlCommand) {
        print("🔌 unlink called...")
        unlinkCallbackId = command.callbackId
        OmronBluetoothManager.sharedInstance.disconnect()
    }

     @objc(isBloodPressureDeviceLinked:)
    func isBloodPressureDeviceLinked(command: CDVInvokedUrlCommand) {
        
        let isConnected = OmronBluetoothManager.sharedInstance.isBloodPressureDevicePresent()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: isConnected)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
}

// MARK: - Bluetooth Delegate
extension OmronDevicePlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is ON OmronDevicePlugin")
        case .poweredOff:
            print("❌ Bluetooth is OFF OmronDevicePlugin")
        case .resetting:
            print("🔄 Bluetooth is resetting OmronDevicePlugin")
        case .unauthorized:
            print("⚠️ Bluetooth is not authorized OmronDevicePlugin")
        case .unsupported:
            print("❌ Device does not support Bluetooth OmronDevicePlugin")
        case .unknown:
            print("🤷 Bluetooth state is unknown OmronDevicePlugin")
        @unknown default:
            print("⚠️ Unknown Bluetooth state OmronDevicePlugin")
        }
    }
}

// MARK: - Omron BLE Delegate
extension OmronDevicePlugin: OmronBluetoothManagerDelegate {
    func didInitialize(isSuccessfully: Bool) {
        print("didInitialize isSuccessfully: \(isSuccessfully)")
        if let callbackId = initializeCallbackId {

            let deviceInfo = ["isSuccessfully": "\(isSuccessfully)"]
            let pluginResult = CDVPluginResult(status: .ok, messageAs: deviceInfo)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        }
    }

    func didFindDevice(isSuccessfully: Bool) {
        print("didFindDevice isSuccessfully: \(isSuccessfully)")
        if let callbackId = searchCallbackId {
            let deviceInfo = ["isSuccessfully": "\(isSuccessfully)"]
            let pluginResult = CDVPluginResult(status: .ok, messageAs: deviceInfo)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
        }
    }

    func didConnectDevice(isSuccessfully: Bool, macId: String) {
        print("didConnectDevice isSuccessfully: \(isSuccessfully) macId: \(macId)")
        if let callbackId = connectAndSyncCallbackId {
            let deviceInfo = ["isSuccessfully": "\(isSuccessfully)", "macId": macId]
             let pluginResult = CDVPluginResult(status: .ok, messageAs: deviceInfo)
            pluginResult.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
            
        }
    }

    func didReceiveBloodPressureData(_ data: [String: Any]) {
        print("didReceiveBloodPressureData: \(data)")
        if let callbackId = connectAndSyncCallbackId {
            let deviceInfo = ["data": data]
            let pluginResult = CDVPluginResult(status: .ok, messageAs: deviceInfo)
            pluginResult.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId: callbackId)
            
        }else{

        }
    }

    func didDisconnectDevice(isSuccessfully: Bool) {
        print("didDisconnectDevice isSuccessfully: \(isSuccessfully)")
    }
}
