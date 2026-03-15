var exec = require('cordova/exec');

var GoqiiPlugin = {
    initializeSDK: function(success, error) {
        exec(success, error, "GoqiiPlugin", "initializeSDK", []);
    },
    startBGMDiscovery: function(success, error) {
        exec(success, error, "GoqiiPlugin", "startBGMDiscovery", []);
    },
    pairBGM: function(success, error) {
        exec(success, error, "GoqiiPlugin", "pairBGM", []);
    },
    connectToKnownDevice: function(success, error) {
        exec(success, error, "GoqiiPlugin", "connectToKnownDevice", []);
    },
    unlinkGlucometer: function(success, error) {
        exec(success, error, "GoqiiPlugin", "unlinkGlucometer", []);
    },
    setGlucometerMacId: function(macId, success, error) {
        exec(success, error, "GoqiiPlugin", "setGlucometerMacId", [macId]);
    },
    isDevicePaired: function(success, error) {
        exec(success, error, "GoqiiPlugin", "isDevicePaired", []);
    },
    setConnectionTimeout: function(ms, success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "setConnectionTimeout", [ms]);
    },
    deviceConnectionState: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "deviceConnectionState", []);
    },
    isDeviceConnected: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "isDeviceConnected", []);
    },
    setSyncAllRecords: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "setSyncAllRecords", []);
    },
    setLiveReadingDelay: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "setLiveReadingDelay", []);
    },
    stopBGMDiscovery: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "stopBGMDiscovery", []);
    },
    pairBGMWithId: function(macId, success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "pairBGMWithId", [macId]);
    },
    stopSync: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "stopSync", []);
    },
    getCurrentDeviceMacId: function(success, error) {
        cordova.exec(success, error, "GoqiiPlugin", "getCurrentDeviceMacId", []);
    }
};

module.exports = GoqiiPlugin;

module.exports.initializeSDK = GoqiiPlugin.initializeSDK;
module.exports.startBGMDiscovery = GoqiiPlugin.startBGMDiscovery;
module.exports.pairBGM = GoqiiPlugin.pairBGM;
module.exports.connectToKnownDevice = GoqiiPlugin.connectToKnownDevice;
module.exports.unlinkGlucometer = GoqiiPlugin.unlinkGlucometer;
module.exports.setGlucometerMacId = GoqiiPlugin.setGlucometerMacId;
module.exports.setConnectionTimeout = GoqiiPlugin.setConnectionTimeout;
module.exports.deviceConnectionState = GoqiiPlugin.deviceConnectionState;
module.exports.isDeviceConnected = GoqiiPlugin.isDeviceConnected;
module.exports.getCurrentDeviceMacId = GoqiiPlugin.getCurrentDeviceMacId;
module.exports.setSyncAllRecords = GoqiiPlugin.setSyncAllRecords;
module.exports.setLiveReadingDelay = GoqiiPlugin.setLiveReadingDelay;
module.exports.stopBGMDiscovery = GoqiiPlugin.stopBGMDiscovery;
module.exports.pairBGMWithId = GoqiiPlugin.pairBGMWithId;
module.exports.stopSync = GoqiiPlugin.stopSync;
module.exports.isDevicePaired = GoqiiPlugin.isDevicePaired;
