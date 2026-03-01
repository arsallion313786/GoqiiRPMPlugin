package com.goqii.goqiiplugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import net.huray.omronsdk.ble.entity.DiscoveredDevice;
import net.huray.omronsdk.ble.entity.SessionData;
import net.huray.omronsdk.ble.enumerate.OHQCompletionReason;
import net.huray.omronsdk.ble.enumerate.OHQConnectionState;
import com.goqii.goqiisdk.OmronDeviceWrapper;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonArray;
import android.text.TextUtils;
import android.os.Handler;
import android.os.Looper;


public class OmronDevicePlugin extends CordovaPlugin implements OmronDeviceWrapper.OmronDeviceCallback {

    private static final String TAG = "OmronDevicePlugin";
    private static final String PREFS_NAME = "GoqiiPluginPrefs";
    private static final String KEY_LAST_SYNC_TIME = "lastOmronSyncTime";
    private static final SimpleDateFormat OMRON_TS_FORMAT =
            new SimpleDateFormat("dd-MM-yyyy hh:mm:ss", Locale.US);

    private OmronDeviceWrapper omronDeviceWrapper;
    // Use a single persistent callback for all async events
    private CallbackContext eventCallbackContext;

    private static long CONNECTION_TIMEOUT_MS = 30_000L;
    private final Handler connectionTimeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable connectionTimeoutRunnable;
    private boolean isConnected = false;
    private String macId = "";
    private String name = "";
    private boolean isPairing = false;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "initializeSDK":
                initialize(callbackContext);
                return true;
            case "registerCallback":
                this.eventCallbackContext = callbackContext;
                // Send a plugin result to keep the callback alive for future events
                PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
                pluginResult.setKeepCallback(true);
                this.eventCallbackContext.sendPluginResult(pluginResult);
                return  true;
            case "pairBPM":
                if (omronDeviceWrapper == null) {
                    callbackContext.error("Plugin not initialized. Call initializeSDK first.");
                    return true;
                }
                isPairing = true;
                startConnectionTimeout();
                omronDeviceWrapper.connectAndSync();
                // Send an immediate OK response to the JS caller
                callbackContext.success();
                return true;

            case "startDeviceDiscovery":
                if (omronDeviceWrapper == null) {
                    callbackContext.error("Plugin not initialized. Call initializeSDK first.");
                    return true;
                }
                startConnectionTimeout();
                omronDeviceWrapper.startScanning();
                callbackContext.success();
                return true;

            case "connectToKnownDevice":
            case "connectAndSync":
                isPairing = false;
                if (omronDeviceWrapper == null) {
                    callbackContext.error("Plugin not initialized. Call initializeSDK first.");
                    return true;
                }
                startConnectionTimeout();
                omronDeviceWrapper.connectAndSync();
                callbackContext.success();
                return true;

            case "disconnect":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnect();
                    callbackContext.success("Device disconnected successfully");
                } else {
                    callbackContext.error("Plugin is not initialized. Call initializeSDK first.");
                }
                return true;

            case "unlink":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnect();
                    omronDeviceWrapper.unpairDevice();
                    callbackContext.success("Device Unlinked successfully");
                } else {
                    callbackContext.error("Plugin is not initialized. Call initializeSDK first.");
                }
                return true;

            case "isDevicePaired":
                if (omronDeviceWrapper != null) {
                    String mac = omronDeviceWrapper.getOmronMac();
                    callbackContext.success(Boolean.toString(!TextUtils.isEmpty(mac)));
                } else {
                    callbackContext.error("Plugin is not initialized. Call initializeSDK first.");
                }
                return true;

            case "deviceConnectionState":
            case "isDeviceConnected":
                sendConnectionState();
                callbackContext.success();
                return true;

            case "setConnectionTimeout":
                if (args.length() > 0) {
                    long timeout = args.getLong(0);
                    CONNECTION_TIMEOUT_MS = timeout;
                }
                callbackContext.success("Connection timeout set successfully");
                return true;

            case "getCurrentDeviceMacId":
                if (omronDeviceWrapper != null) {
                    String mac = omronDeviceWrapper.getOmronMac();
                    callbackContext.success(mac);
                } else {
                    callbackContext.error("Plugin is not initialized. Call initializeSDK first.");
                }
                return true;

            default:
                callbackContext.error("Invalid action: " + action);
                return false;
        }
    }

    private void sendEvent(JSONObject payload) {
        if (this.eventCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, payload);
            result.setKeepCallback(true);
            this.eventCallbackContext.sendPluginResult(result);
        } else {
            Log.w(TAG, "eventCallbackContext is null. Cannot send event.");
        }
    }

    private void sendErrorEvent(JSONObject payload) {
        if (this.eventCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, payload);
            result.setKeepCallback(true);
            this.eventCallbackContext.sendPluginResult(result);
        } else {
            Log.w(TAG, "eventCallbackContext is null. Cannot send error event.");
        }
    }

    private void sendConnectionState() {
        if (omronDeviceWrapper != null) {
            try {
                String mac = omronDeviceWrapper.getOmronMac();
                JSONObject deviceInfo = new JSONObject();
                deviceInfo.put("code", isConnected ? "DEVICE_CONNECTED" : "DEVICE_DISCONNECTED");
                deviceInfo.put("isSuccessfully", isConnected);
                deviceInfo.put("state", isConnected ? "connected" : "disconnected");
                deviceInfo.put("msg", isConnected ? "Device connected" : "Device disconnected");
                deviceInfo.put("macId", mac);
                sendEvent(deviceInfo);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    private void initialize(CallbackContext callbackContext) {
        Context context = cordova.getActivity().getApplicationContext();
        omronDeviceWrapper = new OmronDeviceWrapper(context, this);
        callbackContext.success("OmronDeviceWrapper initialized successfully");
    }

    @Override
    public void onScanResult(List<DiscoveredDevice> discoveredDevices) {
        cancelConnectionTimeout();
        for (DiscoveredDevice device : discoveredDevices) {
            try {
                JSONObject deviceObj = new JSONObject();
                deviceObj.put("macId", device.getAddress());
                deviceObj.put("name", device.getLocalName());
                deviceObj.put("code", "ON_DEVICE_FOUND");
                sendEvent(deviceObj);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onScanCompleted(OHQCompletionReason reason) {
        // This can be a separate event if needed, e.g., ON_SCAN_COMPLETE
        Log.d(TAG, "Scan completed with reason: " + reason.name());
    }

    @Override
    public void onConnected(String macId) {
        try {
            Log.d(TAG, "Device connected: " + macId + " isPairing: " + isPairing);
            cancelConnectionTimeout();
            isConnected = true;
            this.macId = macId;
            JSONObject resultObj = new JSONObject();
            resultObj.put("code", isPairing ? "ON_PAIRING_SUCCESS" : "DEVICE_CONNECTED");
            resultObj.put("MacID", macId);
            resultObj.put("name", "Omron Blood Pressure Monitor");
            resultObj.put("isSuccessfully", true);
            resultObj.put("message", isPairing ? "On pairing success" : "Device connected");
            sendEvent(resultObj);
            isPairing = false;
        } catch (Exception e) {
            Log.e(TAG, "Error processing onConnected event", e);
        }
    }

    private void startConnectionTimeout() {
        cancelConnectionTimeout();
        connectionTimeoutRunnable = () -> {
            if (this.eventCallbackContext != null) {
                Log.w(TAG, "Connection timeout after " + CONNECTION_TIMEOUT_MS + "ms");
                try {
                    JSONObject payload = new JSONObject();
                    payload.put("code", "TIMEOUT_EXCEEDED");
                    payload.put("msg", "Operation timed out. Please try again.");
                    sendErrorEvent(payload);
                } catch (JSONException e) {
                    Log.e(TAG, "Error creating timeout JSON", e);
                }
            }
        };
        connectionTimeoutHandler.postDelayed(connectionTimeoutRunnable, CONNECTION_TIMEOUT_MS);
    }

    private void cancelConnectionTimeout() {
        if (connectionTimeoutRunnable != null) {
            connectionTimeoutHandler.removeCallbacks(connectionTimeoutRunnable);
            connectionTimeoutRunnable = null;
        }
    }

    @Override
    public void onDisconnected() {
        isConnected = false;
        sendConnectionState();
    }

    @Override
    public void onDataSynced(SessionData sessionData) {
        cancelConnectionTimeout();
        try {
            LOG.d("cordova sync", sessionData.toString());

            SharedPreferences prefs = cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            long newSyncTime = System.currentTimeMillis();

            Gson gson = new Gson();
            String jsonString = gson.toJson(sessionData);
            JSONObject jsonObject = new JSONObject(jsonString);
            JSONArray measurementRecordsArray = jsonObject.optJSONArray("measurementRecords");
            JSONArray filteredRecords = new JSONArray();

            if (measurementRecordsArray != null) {
                for (int i = 0; i < measurementRecordsArray.length(); i++) {
                    JSONObject record = measurementRecordsArray.getJSONObject(i);
                    String tsStr = record.optString("TimeStampKey", "");

                    JSONObject parsedRecord = new JSONObject();
                    parsedRecord.put("Unit", record.optString("BloodPressureUnitKey"));
                    parsedRecord.put("Systolic", record.optDouble("SystolicKey"));
                    parsedRecord.put("PulseRate", record.optDouble("PulseRateKey"));
                    parsedRecord.put("Diastolic", record.optDouble("DiastolicKey"));
                    parsedRecord.put("UserID", record.optInt("UserIndexKey"));
                    parsedRecord.put("MeanArterialPressure", record.optDouble("MeanArterialPressureKey"));
                    parsedRecord.put("Timestamp", tsStr);
                    filteredRecords.put(parsedRecord);
                }
            }

            if (!isConnected && filteredRecords.length() == 0) {
                return;
            }

            JSONObject dataObj = new JSONObject();
            dataObj.put("data", filteredRecords);
            dataObj.put("code", "ON_DATA_RECEIVED");
            dataObj.put("msg", "Data synced successfully");
            sendEvent(dataObj);

            prefs.edit().putLong(KEY_LAST_SYNC_TIME, newSyncTime).apply();

        } catch (JSONException e) {
            e.printStackTrace();
            try {
                JSONObject errorData = new JSONObject();
                errorData.put("code", "ERROR");
                errorData.put("msg", "Error parsing session data");
                sendErrorEvent(errorData);
            } catch (JSONException jsonException) {
                jsonException.printStackTrace();
            }
        }
    }

    @Override
    public void onError(String error) {
        cancelConnectionTimeout();
        JSONObject errorObj = new JSONObject();
        try {
            errorObj.put("code", "ERROR");
            errorObj.put("msg", error);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        sendErrorEvent(errorObj);
    }

    @Override
    public void onConnectionStateChanged(OHQConnectionState state) {
        Log.d(TAG, "Connection state changed: " + state.name());
        // You can optionally create a new event here if the JS side needs to know about every state change.
        // For example:
        // try {
        //     JSONObject stateObj = new JSONObject();
        //     stateObj.put("code", "ON_CONNECTION_STATE_CHANGED");
        //     stateObj.put("state", state.name());
        //     sendEvent(stateObj);
        // } catch (JSONException e) {
        //     e.printStackTrace();
        // }
    }
}
