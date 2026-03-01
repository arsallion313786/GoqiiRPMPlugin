package com.goqii.goqiiplugin;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import com.goqii.goqiisdk.GlucometerManager;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class GoqiiPlugin extends CordovaPlugin {
    private static final String TAG = "GoqiiPlugin";
    private static final String PREFS_NAME = "GoqiiPluginPrefs";
    private static final String KEY_LAST_RESULT_STR = "lastGlucometerResultStr";
    private GlucometerManager glucometerManager;
    private CallbackContext eventCallbackContext;

    private static long CONNECTION_TIMEOUT_MS = 20_000L;
    private final Handler connectionTimeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable connectionTimeoutRunnable;
    private volatile boolean syncAcknowledged = false;
    private boolean shouldSyncAllRecords = false;

    private static final long RESYNC_DELAY_MS = 20_000L;
    private final Handler resyncHandler = new Handler(Looper.getMainLooper());
    private Runnable resyncRunnable;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "execute: action = " + action);

        switch (action) {
            case "initializeSDK":
                initializeGlucometer(callbackContext);
                return true;
            case "registerCallback":
                this.eventCallbackContext = callbackContext;
                PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
                pluginResult.setKeepCallback(true);
                this.eventCallbackContext.sendPluginResult(pluginResult);
                return true;
            case "setConnectionTimeout":
                CONNECTION_TIMEOUT_MS = args.getLong(0);
                callbackContext.success("Connection timeout set.");
                return true;
            case "startBGMDiscovery":
                if (glucometerManager != null) {
                    glucometerManager.startScan();
                    callbackContext.success("Scan started.");
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "unlinkGlucometer":
                if (glucometerManager != null) {
                    cancelResync();
                    glucometerManager.unpairDevice();
                    cordova.getActivity()
                            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit().remove(KEY_LAST_RESULT_STR).apply();
                    callbackContext.success("Unlink command issued.");
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "connectToKnownDevice":
                if (glucometerManager != null) {
                    syncAcknowledged = false;
                    startSyncTimeout();
                    glucometerManager.syncGlucometer();
                    callbackContext.success("Sync command issued.");
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "pairBGM":
                if (glucometerManager != null) {
                    glucometerManager.linkDevice();
                    callbackContext.success("Pairing command issued.");
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "isDevicePaired":
                if (glucometerManager != null) {
                    String mac = glucometerManager.getGlucometerMac();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac)));
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "getCurrentDeviceMacId":
                if (glucometerManager != null) {
                    String mac = glucometerManager.getGlucometerMac();
                    callbackContext.success(mac);
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "setGlucometerMacId":
                handleSetMacId(args, callbackContext);
                return true;
            case "isDeviceConnected":
                if (glucometerManager != null) {
                    boolean isConnected = glucometerManager.isDeviceConnected();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, isConnected));
                } else {
                    callbackContext.error("SDK not initialized.");
                }
                return true;
            case "setSyncAllRecords":
                shouldSyncAllRecords = true;
                callbackContext.success("Flag to sync all records has been set.");
                return true;
            default:
                callbackContext.error("Invalid action: " + action);
                return false;
        }
    }

    private void handleSetMacId(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (glucometerManager == null) {
            callbackContext.error("SDK not initialized.");
            return;
        }
        if (args == null || args.length() == 0 || TextUtils.isEmpty(args.getString(0))) {
            callbackContext.error("MAC ID must not be empty.");
            return;
        }

        String localMac = glucometerManager.getGlucometerMac();
        String newMac = args.getString(0);

        if (!TextUtils.isEmpty(localMac) && !localMac.equals(newMac)) {
            callbackContext.error("Passed MAC ID does not match the previously linked MAC ID.");
        } else {
            glucometerManager.setGlucometerMacId(newMac);
            callbackContext.success("MAC ID set successfully.");
        }
    }

    private void sendEvent(JSONObject payload) {
        if (eventCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, payload);
            result.setKeepCallback(true);
            eventCallbackContext.sendPluginResult(result);
        } else {
            Log.w(TAG, "Event callback context is null. Cannot send event.");
        }
    }

    private void sendErrorEvent(JSONObject payload) {
        if (eventCallbackContext != null) {
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, payload);
            result.setKeepCallback(true);
            eventCallbackContext.sendPluginResult(result);
        } else {
            Log.w(TAG, "Event callback context is null. Cannot send error event.");
        }
    }

    public void initializeGlucometer(CallbackContext initCallbackContext) {
        if (glucometerManager != null) {
            initCallbackContext.success("SDK already initialized.");
            return;
        }

        Context context = cordova.getActivity().getApplicationContext();
        glucometerManager = new GlucometerManager(context, new GlucometerManager.GlucometerListener() {
            @Override
            public void onDeviceLinked(String macId, String deviceName) {
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "ON_PAIRING_SUCCESS");
                    result.put("macId", macId);
                    result.put("msg", "Device Linked");
                    result.put("name", deviceName);
                    sendEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onDeviceUnlinked(String macId) {
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "ON_UNLINK_SUCCESS");
                    result.put("macId", macId);
                    result.put("msg", "Device Unlinked");
                    sendEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onDeviceLinkFailed() {
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "ON_PAIRING_FAILED");
                    result.put("msg", "Device Link Failed");
                    sendErrorEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onDeviceUnlinkFailed() {
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "ON_UNPAIRING_FAILED");
                    result.put("msg", "Device Unlink Failed");
                    sendErrorEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onSyncComplete(String resultStr) {
                cancelSyncTimeout();
                syncAcknowledged = true;
                try {
                    SharedPreferences prefs = cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
                    String lastResultStr = prefs.getString(KEY_LAST_RESULT_STR, "");

                    JSONObject jsonObject = new JSONObject(resultStr);
                    JSONArray allRecords = jsonObject.getJSONArray("data");
                    JSONArray newRecords = new JSONArray();

                    if (shouldSyncAllRecords || TextUtils.isEmpty(lastResultStr)) {
                        newRecords = allRecords;
                    } else {
                        java.util.Set<String> previousKeys = new java.util.HashSet<>();
                        try {
                            JSONArray prevRecords = new JSONObject(lastResultStr).getJSONArray("data");
                            for (int i = 0; i < prevRecords.length(); i++) {
                                previousKeys.add(prevRecords.getJSONObject(i).optString("logDate", ""));
                            }
                        } catch (Exception ignored) {}

                        for (int i = 0; i < allRecords.length(); i++) {
                            JSONObject record = allRecords.getJSONObject(i);
                            if (!previousKeys.contains(record.optString("logDate", ""))) {
                                newRecords.put(record);
                            }
                        }
                    }

                    Log.d(TAG, "onSyncComplete: total=" + allRecords.length() + ", new=" + newRecords.length());

                    JSONObject result = new JSONObject();
                    result.put("code", "ON_DATA_RECEIVED");
                    result.put("data", newRecords);
                    result.put("msg", "Glucose data received successfully");
                    sendEvent(result);

                    prefs.edit().putString(KEY_LAST_RESULT_STR, resultStr).apply();
                } catch (Exception e) {
                    Log.e(TAG, "onSyncComplete: error processing result", e);
                    try {
                        JSONObject error = new JSONObject();
                        error.put("code", "DATA_PROCESSING_ERROR");
                        error.put("msg", "Error processing synced data.");
                        sendErrorEvent(error);
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                } finally {
                    shouldSyncAllRecords = false;
                    scheduleResync();
                }
            }

            @Override
            public void deviceNotFound() {
                cancelSyncTimeout();
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "DEVICE_NOT_FOUND");
                    result.put("msg", "Device Not Found");
                    sendErrorEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onDeviceFound(String macId, String deviceName) {
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "ON_DEVICE_FOUND");
                    result.put("macId", macId);
                    result.put("name", deviceName);
                    result.put("msg", "Device Found");
                    sendEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void deviceNotPaired() {
                cancelSyncTimeout();
                try {
                    JSONObject result = new JSONObject();
                    result.put("code", "DEVICE_NOT_PAIRED");
                    result.put("msg", "Device is not paired. Please pair the device first.");
                    sendErrorEvent(result);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        try {
            boolean isBluetoothEnabled = glucometerManager.isBluetoothEnabled();
            String code = isBluetoothEnabled ? "BLUETOOTH_ON" : "BLUETOOTH_OFF";
            String msg = isBluetoothEnabled ? "Bluetooth is enabled." : "Bluetooth is not enabled.";

            JSONObject result = new JSONObject();
            result.put("code", code);
            result.put("msg", msg);

            if (isBluetoothEnabled) {
                initCallbackContext.success(result);
            } else {
                initCallbackContext.error(result);
            }
        } catch (Exception e) {
            initCallbackContext.error("Error checking Bluetooth status: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void startSyncTimeout() {
        cancelSyncTimeout();
        connectionTimeoutRunnable = () -> {
            if (!syncAcknowledged) {
                Log.w(TAG, "Glucometer sync timeout after " + CONNECTION_TIMEOUT_MS + "ms");
                try {
                    JSONObject payload = new JSONObject();
                    payload.put("code", "TIMEOUT_EXCEEDED");
                    payload.put("msg", "We did not receive a response. Please ensure your device is on and try again.");
                    sendErrorEvent(payload);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        };
        connectionTimeoutHandler.postDelayed(connectionTimeoutRunnable, CONNECTION_TIMEOUT_MS);
    }

    private void cancelSyncTimeout() {
        if (connectionTimeoutRunnable != null) {
            connectionTimeoutHandler.removeCallbacks(connectionTimeoutRunnable);
            connectionTimeoutRunnable = null;
        }
    }

    private void scheduleResync() {
        cancelResync();
        resyncRunnable = () -> {
            Log.d(TAG, "Auto-resync triggered after " + RESYNC_DELAY_MS + "ms");
            syncAcknowledged = false;
            shouldSyncAllRecords = false;
            startSyncTimeout();
            if (glucometerManager != null) {
                glucometerManager.syncGlucometer();
            }
        };
        resyncHandler.postDelayed(resyncRunnable, RESYNC_DELAY_MS);
        Log.d(TAG, "Resync scheduled in " + RESYNC_DELAY_MS + "ms");
    }

    private void cancelResync() {
        if (resyncRunnable != null) {
            resyncHandler.removeCallbacks(resyncRunnable);
            resyncRunnable = null;
            Log.d(TAG, "Resync cancelled");
        }
    }
}
