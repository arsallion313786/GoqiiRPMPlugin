package com.goqii.goqiiplugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.bluetooth.BluetoothAdapter;

import net.huray.omronsdk.ble.entity.DiscoveredDevice;
import net.huray.omronsdk.ble.entity.SessionData;
import net.huray.omronsdk.ble.enumerate.OHQCompletionReason;
import net.huray.omronsdk.ble.enumerate.OHQConnectionState;
import com.goqii.goqiisdk.OmronDeviceWrapper;

import java.util.List;

import com.google.gson.Gson;
import android.text.TextUtils;
import android.util.Log;

public class OmronDevicePlugin extends CordovaPlugin implements OmronDeviceWrapper.OmronDeviceCallback {

    private OmronDeviceWrapper omronDeviceWrapper;
    private CallbackContext omronCallbackContext; // The single, persistent callback context

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "initialize":
                initialize(callbackContext);
                return true;

            case "registerCallback":
                // This action sets the persistent callback context
                this.omronCallbackContext = callbackContext;
                // Send a confirmation that the callback is registered
                JSONObject payload = new JSONObject();
                payload.put("event", "callbackRegistered");
                payload.put("data", "Successfully registered for events.");
                PluginResult result = new PluginResult(PluginResult.Status.OK, payload);
                result.setKeepCallback(true); // Keep the callback alive for future events
                this.omronCallbackContext.sendPluginResult(result);
                return true;

            case "startScanning":
                if (omronDeviceWrapper == null) {
                    callbackContext.error("Plugin not initialized.");
                    return false;
                }
                if (omronCallbackContext == null) {
                    callbackContext.error("Callback not registered. Call registerCallback() first.");
                    return false;
                }
                omronDeviceWrapper.startScanning();
                callbackContext.success("Scan command issued."); // Immediate feedback
                return true;

            case "connectAndSync":
                if (omronDeviceWrapper == null) {
                    callbackContext.error("Plugin not initialized.");
                    return false;
                }
                if (omronCallbackContext == null) {
                    callbackContext.error("Callback not registered. Call registerCallback() first.");
                    return false;
                }
                omronDeviceWrapper.connectAndSync();
                callbackContext.success("Connect & Sync command issued."); // Immediate feedback
                return true;

            case "disconnect":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnect();
                    callbackContext.success("Device disconnected successfully.");
                } else {
                    callbackContext.error("Plugin not initialized.");
                }
                return true;

            case "unlink":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.unpairDevice();
                    callbackContext.success("Device unlinked successfully.");
                } else {
                    callbackContext.error("Plugin not initialized.");
                }
                return true;

            case "isBloodPressureDeviceLinked":
                if (omronDeviceWrapper != null) {
                    String mac = omronDeviceWrapper.getOmronMac();
                    PluginResult pResult = new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac));
                    callbackContext.sendPluginResult(pResult);
                } else {
                    callbackContext.error("Plugin not initialized.");
                }
                return true;

            default:
                return false;
        }
    }

    // +------------------------------------------------------------+
    // |         Event & Error Sending Helper Methods               |
    // +------------------------------------------------------------+

    private void sendEvent(String eventName, Object data) {
        if (omronCallbackContext == null) {
            Log.e("OmronDevicePlugin", "Cannot send event, callback context is not registered.");
            return;
        }
        try {
            JSONObject payload = new JSONObject();
            payload.put("event", eventName);
            payload.put("data", data);
            PluginResult result = new PluginResult(PluginResult.Status.OK, payload);
            result.setKeepCallback(true);
            omronCallbackContext.sendPluginResult(result);
        } catch (JSONException e) {
            sendError("Failed to create JSON for event: " + eventName);
        }
    }

    private void sendError(String errorMessage) {
        if (omronCallbackContext == null) {
            Log.e("OmronDevicePlugin", "Cannot send error, callback context is not registered.");
            return;
        }
        JSONObject errorPayload = new JSONObject();
        try {
            errorPayload.put("event", "error");
            errorPayload.put("data", errorMessage);
        } catch (JSONException e) {
            // This should not happen
        }
        PluginResult result = new PluginResult(PluginResult.Status.ERROR, errorPayload);
        result.setKeepCallback(true);
        omronCallbackContext.sendPluginResult(result);
    }

    // +------------------------------------------------------------+
    // |              Plugin Initialization & Helpers               |
    // +------------------------------------------------------------+

    private void initialize(CallbackContext callbackContext) {
        Context context = cordova.getActivity().getApplicationContext();
        omronDeviceWrapper = new OmronDeviceWrapper(context, this);
        callbackContext.success("OmronDeviceWrapper initialized successfully.");
    }


    // +------------------------------------------------------------+
    // |           Omron SDK Callback Implementations               |
    // +------------------------------------------------------------+

    @Override
    public void onScanResult(List<DiscoveredDevice> discoveredDevices) {
        JSONArray resultArray = new JSONArray();
        for (DiscoveredDevice device : discoveredDevices) {
            try {
                JSONObject deviceObj = new JSONObject();
                deviceObj.put("macId", device.getAddress());
                resultArray.put(deviceObj);
            } catch (JSONException e) {
                // Log and ignore the faulty device
                Log.e("OmronDevicePlugin", "Error creating JSON for a discovered device.", e);
            }
        }
        sendEvent("scanResult", resultArray);
    }

    @Override
    public void onScanCompleted(OHQCompletionReason reason) {
        sendEvent("scanCompleted", reason.name());
    }

    @Override
    public void onConnected(String macId) {
        try {
            JSONObject resultObj = new JSONObject();
            resultObj.put("macId", macId);
            resultObj.put("name", "Omron Blood Pressure Monitor");
            sendEvent("connected", resultObj);
        } catch (JSONException e) {
            sendError("Failed to create JSON for onConnected event.");
        }
    }

    @Override
    public void onDisconnected() {
        sendEvent("disconnected", "Device disconnected");
    }

    @Override
    public void onDataSynced(SessionData sessionData) {
        try {
            Gson gson = new Gson();
            String jsonString = gson.toJson(sessionData);
            JSONObject jsonObject = new JSONObject(jsonString);
            JSONArray measurementRecordsArray = jsonObject.optJSONArray("measurementRecords");
            JSONArray parsedRecords = new JSONArray();

            if (measurementRecordsArray != null) {
                for (int i = 0; i < measurementRecordsArray.length(); i++) {
                    JSONObject record = measurementRecordsArray.getJSONObject(i);
                    JSONObject parsedRecord = new JSONObject();
                    parsedRecord.put("Unit", record.optString("BloodPressureUnitKey"));
                    parsedRecord.put("Systolic", record.optDouble("SystolicKey"));
                    parsedRecord.put("PulseRate", record.optDouble("PulseRateKey"));
                    parsedRecord.put("Diastolic", record.optDouble("DiastolicKey"));
                    parsedRecord.put("UserID", record.optInt("UserIndexKey"));
                    parsedRecord.put("MeanArterialPressure", record.optDouble("MeanArterialPressureKey"));
                    parsedRecord.put("Timestamp", record.optString("TimeStampKey"));
                    parsedRecords.put(parsedRecord);
                }
            }
            sendEvent("dataSynced", parsedRecords);
        } catch (JSONException e) {
            sendError("Error parsing session data: " + e.getMessage());
        }
    }

    @Override
    public void onError(String error) {
        sendError(error);
    }

    @Override
    public void onConnectionStateChanged(OHQConnectionState ohqConnectionState) {
        sendEvent("connectionStateChanged", ohqConnectionState.name());
    }
}
