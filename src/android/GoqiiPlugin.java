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

import java.util.HashSet;
import java.util.Set;

public class GoqiiPlugin extends CordovaPlugin {
    private static final String TAG = "GoqiiPlugin";
    private static final String PREFS_NAME = "GoqiiPluginPrefs";
    private static final String KEY_LAST_RESULT_STR = "lastGlucometerResultStr";

    private GlucometerManager glucometerManager;
    private CallbackContext eventCallbackContext;

    private static long CONNECTION_TIMEOUT_MS = 10_000L;
    private final Handler timeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable timeoutRunnable;

    private final Handler resyncHandler = new Handler(Looper.getMainLooper());
    private Runnable resyncRunnable;
    private  long RESYNC_DELAY_MS = 15_000L;

    private volatile boolean syncAcknowledged = false;
    private boolean shouldSyncAllRecords = false;
    private boolean shouldScheduleResync = false;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "execute: " + action);

        switch (action) {
            case "registerCallback":
                this.eventCallbackContext = callbackContext;
                PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
                return true;

            case "initializeSDK":
                initializeGlucometer(callbackContext);
                return true;

            case "setConnectionTimeout":
                CONNECTION_TIMEOUT_MS = args.getLong(0);
                callbackContext.success("Timeout updated to " + CONNECTION_TIMEOUT_MS);
                return true;

            case "startBGMDiscovery":
                if (ensureSDK(callbackContext)) {
                    glucometerManager.startScan(CONNECTION_TIMEOUT_MS);
                    callbackContext.success();
                }
                return true;

            case "stopBGMDiscovery":
                if (ensureSDK(callbackContext)) {
                    glucometerManager.stopScan();
                    callbackContext.success();
                }
                return true;

            case "connectToKnownDevice":
                if (ensureSDK(callbackContext)) {
                    syncAcknowledged = false;
                    //shouldScheduleResync = true;
                    //startSyncTimeout();
                    glucometerManager.syncGlucometer();
                    callbackContext.success();
                }
                return true;

            case "pairBGMWithId":
                if (ensureSDK(callbackContext)) {
                    glucometerManager.linkDeviceWithMacId(args.getString(0));
                    callbackContext.success();
                }
                return true;

            case "unlinkGlucometer":
                if (ensureSDK(callbackContext)) {
                    cancelResync();
                    glucometerManager.unpairDevice();
                    clearLocalCache();
                    callbackContext.success();
                }
                return true;

            case "isDevicePaired":
                if (ensureSDK(callbackContext)) {
                    String mac = glucometerManager.getGlucometerMac();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac)));
                }
                return true;

            case "isDeviceConnected":
                if (ensureSDK(callbackContext)) {
                    boolean connected = glucometerManager.isDeviceConnected();
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, connected));
                }
                return true;

            case "setSyncAllRecords":
                shouldSyncAllRecords = args.optBoolean(0, false);
                callbackContext.success("SyncAllRecords set to: " + shouldSyncAllRecords);
                return true;
            case "getCurrentDeviceMacId":
                String mac = glucometerManager.getGlucometerMac();
                PluginResult pResult = new PluginResult(PluginResult.Status.OK, mac);
                pResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pResult);
                return  true;
            case "startSilentBackgroundPolling":
                long resyncDelayMs = 15_000L;
                // Your default value
                if (!args.isNull(0)) {
                    double passedValue = args.optDouble(0, 15000.0);
                    resyncDelayMs = (long) passedValue;
                }
                RESYNC_DELAY_MS = resyncDelayMs;
                shouldScheduleResync = true;
                scheduleResync();
                return  true;
            case "stopSilentBackgroundPolling":
                shouldScheduleResync = false;
                cancelResync();
                return true;
            default:
                return false;
        }
    }

    private boolean ensureSDK(CallbackContext callback) {
        if (glucometerManager == null) {
            callback.error("SDK Not Initialized");
            return false;
        }
        return true;
    }

    private void clearLocalCache() {
        cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().remove(KEY_LAST_RESULT_STR).apply();
    }

    private void initializeGlucometer(CallbackContext callback) {
        if (glucometerManager != null) {
            callback.success("Already initialized");
            return;
        }

        glucometerManager = new GlucometerManager(cordova.getActivity(), new GlucometerManager.GlucometerListener() {
            @Override
            public void onDeviceLinked(String macId, String name) {
                sendNotification("ON_PAIRING_SUCCESS", "Device Linked", macId, name, null);
            }

            @Override
            public void onSyncComplete(String resultStr) {
                cancelSyncTimeout();
                syncAcknowledged = true;
                processSyncData(resultStr);
            }

            @Override
            public void deviceNotFound() {
                cancelSyncTimeout();
                sendErrorNotification("DEVICE_NOT_FOUND", "Device Not Found");
            }

            @Override
            public void onDevicesFound(JSONArray devices) {
                sendNotification("ON_DEVICE_FOUND", "Discovery Update", null, null, devices);
            }

            @Override
            public void onDeviceConnected() {
                sendNotification("DEVICE_CONNECTED", "Connected", null, null, null);
            }

            @Override
            public void onDeviceDisconnected() {
                sendNotification("DEVICE_DISCONNECTED", "Disconnected", null, null, null);
            }

            @Override
            public void onDeviceLinkFailed() { sendErrorNotification("ON_PAIRING_FAILED", "Link Failed"); }
            @Override
            public void onDeviceUnlinked(String mac) { sendNotification("ON_UNLINK_SUCCESS", "Unlinked", mac, null, null); }
            @Override
            public void deviceNotPaired() { sendErrorNotification("NO_PAIRED_DEVICE", "Not Paired"); }
            @Override
            public void onDeviceUnlinkFailed() { sendErrorNotification("ON_UNPAIRING_FAILED", "Unlink Failed"); }
        });

        callback.success("SDK Initialized");
    }

    private void processSyncData(String rawJson) {
        try {
            SharedPreferences prefs = cordova.getActivity().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            String lastData = prefs.getString(KEY_LAST_RESULT_STR, "");

            JSONObject currentObj = new JSONObject(rawJson);
            JSONArray currentRecords = currentObj.getJSONArray("data");

            Set<String> seenKeys = new HashSet<>();
            if (!lastData.isEmpty()) {
                JSONArray lastRecords = new JSONObject(lastData).getJSONArray("data");
                for (int i = 0; i < lastRecords.length(); i++) {
                    seenKeys.add(lastRecords.getJSONObject(i).optString("logDate"));
                }
            }

            JSONArray filtered = new JSONArray();
            for (int i = 0; i < currentRecords.length(); i++) {
                JSONObject rec = currentRecords.getJSONObject(i);
                if (shouldSyncAllRecords || !seenKeys.contains(rec.optString("logDate"))) {
                    filtered.put(rec);
                }
            }

            prefs.edit().putString(KEY_LAST_RESULT_STR, rawJson).apply();
            sendNotification("ON_DATA_RECEIVED", "Data Synced", null, null, filtered);

        } catch (Exception e) {
            sendErrorNotification("DATA_PROCESSING_ERROR", e.getMessage());
        } finally {
            shouldSyncAllRecords = false;
            //scheduleResync();
        }
    }

    // --- Helpers ---

    private void sendNotification(String code, String msg, String mac, String name, Object data) {
        if (eventCallbackContext == null) return;
        try {
            JSONObject res = new JSONObject();
            res.put("code", code);
            res.put("msg", msg);
            if (mac != null) res.put("macId", mac);
            if (name != null) res.put("name", name);
            if (data != null) res.put("data", data);

            PluginResult result = new PluginResult(PluginResult.Status.OK, res);
            result.setKeepCallback(true);
            eventCallbackContext.sendPluginResult(result);
        } catch (JSONException e) { e.printStackTrace(); }
    }

    private void sendErrorNotification(String code, String msg) {
        if (eventCallbackContext == null) return;
        try {
            JSONObject res = new JSONObject();
            res.put("code", code);
            res.put("msg", msg);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, res);
            result.setKeepCallback(true);
            eventCallbackContext.sendPluginResult(result);
        } catch (JSONException e) { e.printStackTrace(); }
    }

    private void startSyncTimeout() {
        cancelSyncTimeout();
        timeoutRunnable = () -> {
            if (!syncAcknowledged) {
                sendErrorNotification("TIMEOUT_EXCEEDED", "No response from device.");
            }
        };
        timeoutHandler.postDelayed(timeoutRunnable, CONNECTION_TIMEOUT_MS);
    }

    private void cancelSyncTimeout() {
        if (timeoutRunnable != null) timeoutHandler.removeCallbacks(timeoutRunnable);
    }

    private void scheduleResync() {
        cancelResync();
        resyncRunnable = () -> {
            String mac = glucometerManager.getGlucometerMac();

            if (eventCallbackContext != null && !TextUtils.isEmpty(mac) && shouldScheduleResync) {
                Log.d(TAG, "Auto-resync triggered after " + RESYNC_DELAY_MS + "ms");
                // syncAcknowledged = false;
                shouldSyncAllRecords = false;
                glucometerManager.syncGlucometer();
                scheduleResync();
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