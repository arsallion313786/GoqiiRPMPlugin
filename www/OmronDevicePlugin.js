var exec = require('cordova/exec');

var OmronDevicePlugin = {
    initializeSDK: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "initializeSDK", []);
    },
    startDeviceDiscovery: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "startDeviceDiscovery", []);
    },
    connectAndSync: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "connectAndSync", []);
    },
    disconnect: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "disconnect", []);
    },
    unlink: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "unlink", []);
    },
    connectToKnownDevice: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "connectToKnownDevice", []);
    },
    pairBPM: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "pairBPM", []);
    },
    getCurrentDeviceMacId: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "getCurrentDeviceMacId", []);
    },
    setConnectionTimeout: function(ms, success, error) {
        exec(success, error, "OmronDevicePlugin", "setConnectionTimeout", [ms]);
    },
    deviceConnectionState: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "deviceConnectionState", []);
    },
    isDeviceConnected: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "isDeviceConnected", []);
    },
    stopDeviceDiscovery: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "stopDeviceDiscovery", []);
    },
    pairBPMWithId: function(macId, success, error) {
        exec(success, error, "OmronDevicePlugin", "pairBPMWithId", [macId]);
    },
    disconnectOnlyBLE: function(success, error) { 
        exec(success, error, "OmronDevicePlugin", "disconnectOnlyBLE", []); 
    },
    isDevicePaired: function(success, error) {
        exec(success, error, "OmronDevicePlugin", "isDevicePaired", []);
    }
};

module.exports = OmronDevicePlugin;

module.exports.initializeSDK = OmronDevicePlugin.initializeSDK;
module.exports.startDeviceDiscovery = OmronDevicePlugin.startDeviceDiscovery;
module.exports.connectAndSync = OmronDevicePlugin.connectAndSync;
module.exports.disconnect = OmronDevicePlugin.disconnect;
module.exports.unlink = OmronDevicePlugin.unlink;
module.exports.pairBPM = OmronDevicePlugin.pairBPM;
module.exports.connectToKnownDevice = OmronDevicePlugin.connectToKnownDevice;
module.exports.getCurrentDeviceMacId = OmronDevicePlugin.getCurrentDeviceMacId;
module.exports.setConnectionTimeout = OmronDevicePlugin.setConnectionTimeout;
module.exports.deviceConnectionState = OmronDevicePlugin.deviceConnectionState;
module.exports.isDeviceConnected = OmronDevicePlugin.isDeviceConnected;
module.exports.stopDeviceDiscovery = OmronDevicePlugin.stopDeviceDiscovery;
module.exports.pairBPMWithId = OmronDevicePlugin.pairBPMWithId;
module.exports.disconnectOnlyBLE = OmronDevicePlugin.disconnectOnlyBLE;
module.exports.isDevicePaired = OmronDevicePlugin.isDevicePaired;
