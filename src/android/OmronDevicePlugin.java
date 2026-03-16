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
    private CallbackContext scanCallbackContext;

    private static long CONNECTION_TIMEOUT_MS = 30_000L;
    private final Handler connectionTimeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable connectionTimeoutRunnable;
    private boolean isConnected = false;
    private String macId = "";
    private String name = "";
    private boolean isPairing = false;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
            case "initializeSDK":
                initialize();
                return true;
            case "registerCallback":
                this.scanCallbackContext = callbackContext;
                // Send a plugin result to keep the callback alive for future events
                PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
                pluginResult.setKeepCallback(true);
                this.scanCallbackContext.sendPluginResult(pluginResult);
                return  true;

            case "pairBPM":
                if (omronDeviceWrapper == null) {
                    initialize();
                }
                isPairing = true;

                omronDeviceWrapper.connectAndSync("");
                return true;
            case "pairBPMWithId":
                if (omronDeviceWrapper == null) {
                    initialize();
                }
                isPairing = true;
                omronDeviceWrapper.connectAndSync(args.getString(0));

                return true;
            case "startDeviceDiscovery":
                if (omronDeviceWrapper == null) {
                    initialize();
                }

                omronDeviceWrapper.startScanning();
                return true;

            case "stopDeviceDiscovery":
                if (omronDeviceWrapper == null) {
                    initialize();
                }
                omronDeviceWrapper.stopScanning();
                cancelConnectionTimeout();
                return true;

            case "connectToKnownDevice":
            case "connectAndSync":
                isPairing = false;
                if (omronDeviceWrapper == null) {
                    initialize();
                }
                
                omronDeviceWrapper.connectAndSync("");
                return true;

            case "disconnectOnlyBLE":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnectOnlyBLE();
                    PluginResult result = new PluginResult(PluginResult.Status.OK, "Device disconnected successfully");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } else {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Plugin is not initialized. Call initializeSDK first.");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                }
                return true;

            case "disconnect":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnect();
                    PluginResult result = new PluginResult(PluginResult.Status.OK, "Device disconnected successfully");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } else {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Plugin is not initialized. Call initializeSDK first.");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                }
                return true;

            case "unlink":
                if (omronDeviceWrapper != null) {
                    omronDeviceWrapper.disconnect();
                    omronDeviceWrapper.unpairDevice();
                    PluginResult result = new PluginResult(PluginResult.Status.OK, "Device Unlinked successfully");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } else {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Plugin is not initialized. Call initializeSDK first.");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                }
                return true;

            case "isDevicePaired":
                if (omronDeviceWrapper != null) {
                    String mac =  omronDeviceWrapper.getOmronMac();

                    PluginResult pResult = new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac));
                    pResult.setKeepCallback(true);
                    callbackContext.sendPluginResult(pResult); 
                } else {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Plugin is not initialized. Call initializeSDK first.");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                }
                return true;
                
            case "deviceConnectionState":
                sendConnectionState();
                return true;

            case "isDeviceConnected":
                PluginResult isConnResult = new PluginResult(PluginResult.Status.OK, isConnected);
                isConnResult.setKeepCallback(true);
                callbackContext.sendPluginResult(isConnResult);
                return true;

            case "setConnectionTimeout":
                if (args.length() > 0) {
                    long timeout = args.getLong(0);
                    CONNECTION_TIMEOUT_MS = timeout;    
                }
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, "Connection timeout set successfully");
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
                return true;

            case "getCurrentDeviceMacId":
                if (omronDeviceWrapper != null) {
                    String mac =  omronDeviceWrapper.getOmronMac();
                    PluginResult result = new PluginResult(PluginResult.Status.OK, mac);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } else {
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Plugin is not initialized. Call initializeSDK first.");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                }
                return true;
                
            default:
                return true;
        }
    }

    private void sendConnectionState() {
        try {
                if (omronDeviceWrapper == null) {
                    initialize();
                }
                String mac =  omronDeviceWrapper.getOmronMac();
                JSONObject deviceInfo = new JSONObject();
                deviceInfo.put("code", isConnected ? "DEVICE_CONNECTED" : "DEVICE_DISCONNECTED");
                deviceInfo.put("isSuccessfully", isConnected);
                deviceInfo.put("state", isConnected ? "connected" : "disconnected");   
                deviceInfo.put("msg", isConnected ? "Device connected" : "Device disconnected");
                deviceInfo.put("macId", mac );
                deviceInfo.put("MacID", mac );

                PluginResult connectionResult = new PluginResult(PluginResult.Status.OK, deviceInfo);
                connectionResult.setKeepCallback(true);

                if (scanCallbackContext != null) {
                    scanCallbackContext.sendPluginResult(connectionResult);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
    }

    private void initialize() {
        Context context = cordova.getActivity().getApplicationContext();
        omronDeviceWrapper = new OmronDeviceWrapper(context, this);

        PluginResult result = new PluginResult(PluginResult.Status.OK, "OmronDeviceWrapper initialized successfully");
        result.setKeepCallback(true);
        scanCallbackContext.sendPluginResult(result);
    }

    @Override
    public void onScanResult(JSONArray discoveredDevices) {
        cancelConnectionTimeout();
        omronDeviceWrapper.stopScanning();
        // JSONArray devices = new JSONArray();
        JSONObject respObj = new JSONObject();
        // for (DiscoveredDevice device : discoveredDevices) {

        //     try {
        //         JSONObject deviceObj = new JSONObject();
        //         deviceObj.put("id", device.getAddress());
        //         deviceObj.put("name", device.getLocalName());
        //         deviceObj.put("rssi", device.getRssi());
        //         devices.put(deviceObj);
        //     } catch (JSONException e) {
        //         e.printStackTrace();
        //     }
        // }
        try {
            respObj.put("code", "ON_DEVICE_FOUND");
            respObj.put("data", discoveredDevices);
        }catch(Exception e){
            e.printStackTrace();
        }
        PluginResult result = new PluginResult(PluginResult.Status.OK, respObj);
        result.setKeepCallback(true);
        scanCallbackContext.sendPluginResult(result);
    }

    @Override
    public void onScanCompleted(OHQCompletionReason reason) {
        // scanCallbackContext.success("Scan completed: " + reason.name());
    }

    @Override
    public void onConnected(String macId) {
        try {
            Log.d(TAG, "Device connected: " + macId + " isPairing: " + isPairing);
            cancelConnectionTimeout();
            isConnected = true;
            JSONObject resultObj = new JSONObject();
            resultObj.put("code", isPairing ? "ON_PAIRING_SUCCESS" : "DEVICE_CONNECTED");
            resultObj.put("macId", macId);
            resultObj.put("MacID", macId);
            resultObj.put("name", "Omron Blood Pressure Monitor");
            resultObj.put("isSuccessfully", true);
            resultObj.put("msg", isPairing ? "On pairing success" : "Device connected");
            PluginResult result = new PluginResult(PluginResult.Status.OK, resultObj);
            result.setKeepCallback(true);
            scanCallbackContext.sendPluginResult(result);
            Log.d(TAG, "event sent: " + macId + " isPairing: " + isPairing);
            isPairing = false;
        } catch (Exception e) {
            Log.d(TAG, "Error sending connection result: " + macId + " isPairing: " + isPairing);
            e.printStackTrace();
        }
    }

    // ── Timeout helpers ────────────────────────────────────────────────────────

    private void startConnectionTimeout() {
        cancelConnectionTimeout();
        connectionTimeoutRunnable = new Runnable() {
            @Override
            public void run() {
                if (scanCallbackContext != null) {
                    Log.w(TAG, "Connection timeout after " + CONNECTION_TIMEOUT_MS + "ms");
                    try {
                        JSONObject payload = new JSONObject();
                        payload.put("code", "TIMEOUT_EXCEEDED");
                        payload.put("msg", "Operation timed out. Please try again.");
                        PluginResult timeoutResult = new PluginResult(
                                PluginResult.Status.ERROR, payload);
                        timeoutResult.setKeepCallback(true);
                        scanCallbackContext.sendPluginResult(timeoutResult);
                    } catch (JSONException e) {
                        // keepcallback
                        PluginResult timeoutResult = new PluginResult(
                                PluginResult.Status.ERROR, "TIMEOUT_EXCEEDED");
                        timeoutResult.setKeepCallback(true);
                        scanCallbackContext.sendPluginResult(timeoutResult);
                    }
                }
            }
        };
        connectionTimeoutHandler.postDelayed(connectionTimeoutRunnable, CONNECTION_TIMEOUT_MS);
    }

    private void cancelConnectionTimeout() {
        try {
            if (connectionTimeoutRunnable != null) {
                connectionTimeoutHandler.removeCallbacks(connectionTimeoutRunnable);
                connectionTimeoutRunnable = null;
            }
        } catch(Exception e) {
            e.printStackTrace();
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
        JSONObject dataObj = new JSONObject();
        try {
            LOG.d("cordova sync", sessionData.toString());

            // Retrieve last sync time (0 = first ever sync → return all records)
            SharedPreferences prefs = cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            long lastSyncTime = prefs.getLong(KEY_LAST_SYNC_TIME, 0);
            long newSyncTime = System.currentTimeMillis();

            Gson gson = new Gson();
            String jsonString = gson.toJson(sessionData);
            JSONObject jsonObject = new JSONObject(jsonString);
            JSONArray measurementRecordsArray = jsonObject.optJSONArray("measurementRecords");

            JSONArray measurementRecords = new JSONArray();
            if (measurementRecordsArray != null) {
                for (int i = 0; i < measurementRecordsArray.length(); i++) {
                    JSONObject record = measurementRecordsArray.getJSONObject(i);

                    // Parse "dd-MM-yyyy hh:mm:ss" → epoch ms for filtering
                    String tsStr = record.optString("TimeStampKey", "");
                    // long recordTimeMs = parseOmronTimestamp(tsStr);

                    // if (recordTimeMs < lastSyncTime) {
                    //     // Record is older than the last sync — skip it
                    //     continue;
                    // }

                    JSONObject parsedRecord = new JSONObject();
                    parsedRecord.put("Unit", record.optString("BloodPressureUnitKey"));
                    parsedRecord.put("Systolic", record.optDouble("SystolicKey"));
                    parsedRecord.put("PulseRate", record.optDouble("PulseRateKey"));
                    parsedRecord.put("Diastolic", record.optDouble("DiastolicKey"));
                    parsedRecord.put("UserID", record.optInt("UserIndexKey"));
                    parsedRecord.put("MeanArterialPressure", record.optDouble("MeanArterialPressureKey"));
                    parsedRecord.put("Timestamp", tsStr);

                    measurementRecords.put(parsedRecord);
                }
            }
            Log.d(TAG, "onDataSynced: total=" + (measurementRecordsArray != null ? measurementRecordsArray.length() : 0)
                    + ", filtered=" + measurementRecords.length()
                    + ", lastSyncTime=" + lastSyncTime);

            dataObj.put("data", measurementRecords);
            dataObj.put("code", "ON_DATA_RECEIVED");
            dataObj.put("msg", "Data synced successfully");

            PluginResult result = new PluginResult(PluginResult.Status.OK, dataObj);
            result.setKeepCallback(true);
            scanCallbackContext.sendPluginResult(result);

            // Persist the new sync time only AFTER sending the result
            prefs.edit().putLong(KEY_LAST_SYNC_TIME, newSyncTime).apply();

        } catch (JSONException e) {
            e.printStackTrace();
            JSONObject data = new JSONObject();
            try {
                data.put("message", "Error parsing session data");
            } catch (JSONException jsonException) {
                jsonException.printStackTrace();
            }
            PluginResult errorResult = new PluginResult(PluginResult.Status.ERROR, data);
            errorResult.setKeepCallback(true);
            scanCallbackContext.sendPluginResult(errorResult);
        }
    }

    /**
     * Parses an Omron timestamp string in "dd-MM-yyyy hh:mm:ss" format to epoch milliseconds.
     * Returns 0 if parsing fails (record will pass the filter and be included).
     */
    private long parseOmronTimestamp(String timestamp) {
        if (timestamp == null || timestamp.isEmpty()) return 0;
        try {
            Date date = OMRON_TS_FORMAT.parse(timestamp);
            return date != null ? date.getTime() : 0;
        } catch (ParseException e) {
            Log.e(TAG, "parseOmronTimestamp: failed to parse '" + timestamp + "'", e);
            return 0;
        }
    }

    @Override
    public void onError(String error) {
        cancelConnectionTimeout(); // also cancel if an SDK error fires before onConnected
        JSONObject errorObj = new JSONObject();
        try {
            errorObj.put("code", "ERROR");
            errorObj.put("msg", error);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        PluginResult errorResult = new PluginResult(PluginResult.Status.ERROR, errorObj);   
        errorResult.setKeepCallback(true);
        scanCallbackContext.error(error);
    }

    @Override
    public void onConnectionStateChanged(OHQConnectionState state) {
    }
}
