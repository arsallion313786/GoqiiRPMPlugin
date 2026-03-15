package com.goqii.goqiiplugin;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import com.goqii.goqiisdk.GlucometerManager;
import android.text.TextUtils;

public class GoqiiPlugin extends CordovaPlugin {
    private static final String TAG = "GoqiiPlugin";
    private static final String PREFS_NAME = "GoqiiPluginPrefs";
    private static final String KEY_LAST_SYNC_TIME = "lastGlucometerSyncTime";
    private static final String KEY_LAST_RESULT_STR = "lastGlucometerResultStr";
    private GlucometerManager glucometerManager;
    private CallbackContext lastCommandCallback;

    private static long CONNECTION_TIMEOUT_MS = 10_000L;
    private final Handler connectionTimeoutHandler = new Handler(Looper.getMainLooper());
    private Runnable connectionTimeoutRunnable;
    private volatile boolean syncAcknowledged = false;
    private CallbackContext isDeviceConnectedCallback;
    private boolean shouldSyncAllRecords = false;

    private static final long RESYNC_DELAY_MS = 20_000L;
    private final Handler resyncHandler = new Handler(Looper.getMainLooper());
    private Runnable resyncRunnable;
    private boolean stopBGMSync = false;
    private boolean shouldScheduleResync = false;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "execute: action = " + action);
        // if(action != null && !action.equals("isDevicePaired") && !action.equals("getCurrentDeviceMacId")){
        // lastCommandCallback = callbackContext;
        // }

        if (action.equals("isDeviceConnected")) {
            isDeviceConnectedCallback = callbackContext;
        } else if (action.equals("initializeSDK") ||
                   action.equals("startBGMDiscovery") ||
                   action.equals("pairBGMWithId") ||
                   action.equals("connectToKnownDevice")
                )  {
            lastCommandCallback = callbackContext;
        }
        if (action.equals("setConnectionTimeout")){
            CONNECTION_TIMEOUT_MS = args.getLong(0);
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, "Connection timeout set successfully");
            pResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pResult);
            return true;
        } else if (action.equals("initializeSDK")) {
            initializeGlucometer();
            return true;
        } else if (action.equals("startBGMDiscovery")) {
            glucometerManager.startScan(CONNECTION_TIMEOUT_MS);
            return true;
        } else if (action.equals("stopBGMDiscovery")) {
            glucometerManager.stopScan();
            return true;
        } else if (action.equals("unlinkGlucometer")) {
            cancelResync();
            glucometerManager.unpairDevice();
            cordova.getActivity()
                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit().remove(KEY_LAST_RESULT_STR).remove(KEY_LAST_SYNC_TIME).apply();
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, "Device Unlinked successfully");
            pResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pResult);
            return true;
        } else if (action.equals("connectToKnownDevice")) {
            syncAcknowledged = false;
            shouldScheduleResync = true;
            startSyncTimeout();
            glucometerManager.syncGlucometer();
            return true;
        } else if(action.equals("stopSync")){
            stopBGMSync = true;
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, "Sync Stopped");
            pResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pResult);
            return true;
        } else if (action.equals("pairBGMWithId")) {
            glucometerManager.linkDeviceWithMacId(args.getString(0));
            return true;
        }else /*if (action.equals("pairBGM")) {
            glucometerManager.linkDevice();
            return true;
        }else*/ if (action.equals("isDevicePaired")) {
            String mac = glucometerManager.getGlucometerMac();
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac));
            pResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pResult);
            return true;
        }else if (action.equals("getCurrentDeviceMacId")) {
            String mac = glucometerManager.getGlucometerMac();
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, mac);
            pResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pResult);
            return true;
        } else if (action.equals("setGlucometerMacId")) {
            if (args != null && args.length() != 0) {
                String localMac = glucometerManager.getGlucometerMac();
                if (TextUtils.isEmpty(args.getString(0))) {
                    try {
                        // JSONObject result = new JSONObject();
                        // result.put("message", "Pass MAC ID");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, localMac);
                        pResult.setKeepCallback(true);
                        callbackContext.sendPluginResult(pResult);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    return true;
                } else if (!TextUtils.isEmpty(localMac) && !localMac.equals(args.getString(0))) {
                    try {
                        JSONObject result = new JSONObject();
                        result.put("msg", "Pass previously linked MAC ID");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        pResult.setKeepCallback(true);
                        callbackContext.sendPluginResult(pResult);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    return true;
                } else {
                    glucometerManager.setGlucometerMacId(args.getString(0));
                    try {
                        JSONObject result = new JSONObject();
                        result.put("msg", "MAC ID set successfully");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result.toString());
                        pResult.setKeepCallback(true);
                        callbackContext.sendPluginResult(pResult);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    return true;
                }
            }
            return true;
        }else if(action.equals("isDeviceConnected")) {
            boolean isConnected = glucometerManager.isDeviceConnected();
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, isConnected);
            pResult.setKeepCallback(true);
            isDeviceConnectedCallback.sendPluginResult(pResult);
            return true;
        } else if(action.equals("setSyncAllRecords")){
            shouldSyncAllRecords = true;
            try {
                JSONObject result = new JSONObject();
                result.put("code", "FLAG_UPDATED");
                result.put("msg", "Sync all records set");
                PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                pResult.setKeepCallback(true);
                lastCommandCallback.sendPluginResult(pResult);
            } catch (Exception e) {
                e.printStackTrace();
            }
            return true;
        }
        return true;
    }

    /*
     * Initialize the Glucometer SDK
     */
    public void initializeGlucometer() {
        Context context = cordova.getActivity();
        if(glucometerManager == null) {
            glucometerManager = new GlucometerManager(context, new GlucometerManager.GlucometerListener() {
                @Override
                public void onDeviceLinked(String macId, String deviceName) {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "ON_PAIRING_SUCCESS");
                        result.put("macId", macId);
                        result.put("MacID", macId);
                        result.put("msg", "Device Linked");
                        result.put("name", deviceName);
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceUnlinked(String macId) {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("msg", "Device Unlinked");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceLinkFailed() {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "ON_PAIRING_FAILED");
                        result.put("msg", "Device Link Failed");                    
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceUnlinkFailed() {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "ON_UNPAIRING_FAILED");
                        result.put("msg", "Device Unlink Failed");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult);
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onSyncComplete(String resultStr) {
                    // Cancel timeout — data arrived in time
                    cancelSyncTimeout();
                    syncAcknowledged = true;
                    if(stopBGMSync){
                        stopBGMSync = false;
                        return;
                    }
                    try {
                        SharedPreferences prefs = cordova.getActivity()
                                .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

                        // Load the previous raw result string (empty on first sync)
                        String lastResultStr = prefs.getString(KEY_LAST_RESULT_STR, "");

                        JSONObject jsonObject = new JSONObject(resultStr);
                        JSONArray allRecords = jsonObject.getJSONArray("data");

                        // Build a Set of unique keys from the PREVIOUS result
                        java.util.Set<String> previousKeys = new java.util.HashSet<>();
                        if (!lastResultStr.isEmpty()) {
                            try {
                                JSONObject prevJson = new JSONObject(lastResultStr);
                                JSONArray prevRecords = prevJson.getJSONArray("data");
                                for (int i = 0; i < prevRecords.length(); i++) {
                                    JSONObject rec = prevRecords.getJSONObject(i);
                                    // Use logDate as a unique fingerprint per record
                                    String key = rec.optString("logDate", "");
                                    previousKeys.add(key);
                                }
                            } catch (Exception exc) {exc.printStackTrace();}
                        }

                        // Only keep records NOT present in the previous result
                        JSONArray newRecords = new JSONArray();
                        for (int i = 0; i < allRecords.length(); i++) {
                            JSONObject record = allRecords.getJSONObject(i);
                            String key = record.optString("logDate", "");
                            if (!previousKeys.contains(key) || shouldSyncAllRecords) {
                                newRecords.put(record);
                            }
                        }

                        Log.d(TAG, "onSyncComplete: total=" + allRecords.length()
                                + ", new=" + newRecords.length()
                                + ", previousKnown=" + previousKeys.size());

                        JSONObject result = new JSONObject();
                        result.put("code", "ON_DATA_RECEIVED");
                        result.put("data", newRecords);
                        result.put("msg", "Glucose data received successfully");
                        PluginResult pResult = new PluginResult(
                                PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult);

                        // Save the current raw result as the new baseline
                        prefs.edit().putString(KEY_LAST_RESULT_STR, resultStr).apply();

                        // Schedule a resync after 20 seconds
                    } catch (Exception e) {
                        Log.e(TAG, "onSyncComplete: error processing result", e);
                        // Fall back to sending raw result so the caller still gets data
                        try {
                            JSONObject result = new JSONObject();
                            result.put("code", "DEVICE_CONNECTION_ERROR");
                            result.put("msg", "Device is connection error.");
                            PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result);
                            pResult.setKeepCallback(true);
                            lastCommandCallback.sendPluginResult(pResult);
                        } catch(Exception ex){
                            ex.printStackTrace();
                        }
                    } finally {
                        shouldSyncAllRecords = false;
                        scheduleResync();
                    }
                }

                @Override
                public void deviceNotFound() {
                    cancelSyncTimeout(); // SDK determined no device — cancel timeout
                    try {
                        JSONObject result = new JSONObject();
                        result.put("code", "DEVICE_NOT_FOUND");
                        result.put("msg", "Device Not Found");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                
                @Override
                public void onDevicesFound(JSONArray devices){
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "ON_DEVICE_FOUND");
                        result.put("data", devices);
                        result.put("msg", "Devices Found");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult);
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                // @Override
                // public void onDeviceFound(String macId, String deviceName) {
                //     try{
                //         JSONObject result = new JSONObject();
                //         result.put("code", "ON_DEVICE_FOUND");
                //         result.put("macId", macId);
                //         result.put("name", deviceName);
                //         result.put("msg", "Device Found");
                //         // lastCommandCallback.success(result.toString());
            
                //         PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                //         pResult.setKeepCallback(true);
                //         lastCommandCallback.sendPluginResult(pResult); 
                //     }catch(Exception e){
                //         e.printStackTrace();
                //     }
                // }

                @Override
                public void deviceNotPaired() {
                    cancelSyncTimeout(); // SDK error — cancel timeout
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "DEVICE_CONNECTION_ERROR");
                        result.put("msg", "Error pairing");    
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceConnected() {
                    if (isDeviceConnectedCallback == null)
                        return;
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "DEVICE_CONNECTED");
                        result.put("msg", "Device connected successfully");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        isDeviceConnectedCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceDisconnected() {
                    if (isDeviceConnectedCallback == null)
                        return;
                    try{
                        JSONObject result = new JSONObject();
                        result.put("code", "DEVICE_DISCONNECTED");
                        result.put("msg", "Device disconnected successfully");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        isDeviceConnectedCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }

                }
                
            });
        }

        try{
            JSONObject result = new JSONObject();
            boolean isBluetoothEnabled = glucometerManager.isBluetoothEnabled();
            result.put("code", isBluetoothEnabled ? "BLUETOOTH_ON" : "BLUETOOTH_OFF");
            result.put("msg", isBluetoothEnabled ? "Bluetooth is enabled." : "Bluetooth is not enabled.");

            PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
            pResult.setKeepCallback(true);
            lastCommandCallback.sendPluginResult(pResult);
        }catch(Exception e){
            e.printStackTrace();
        }
    }

    // ── Timeout helpers ────────────────────────────────────────────────────────

    private void startSyncTimeout() {
        cancelSyncTimeout(); // clear any stale runnable
        connectionTimeoutRunnable = () -> {
            if (!syncAcknowledged && lastCommandCallback != null) {
                Log.w(TAG, "Glucometer sync timeout after " + CONNECTION_TIMEOUT_MS + "ms");
                try {
                    JSONObject payload = new JSONObject();
                    payload.put("code", "TIMEOUT_EXCEEDED");
                    payload.put("msg", "We did not receive a response. Please ensure your device is on and try again.");
                    PluginResult timeoutResult = new PluginResult(
                            PluginResult.Status.ERROR, payload.toString());
                    timeoutResult.setKeepCallback(true);
                    lastCommandCallback.sendPluginResult(timeoutResult);
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
        if (!shouldScheduleResync) {
            Log.d(TAG, "Resync skipped — not triggered by startSync");
            return;
        }
        shouldScheduleResync = false; // consume the flag so only one resync fires
        cancelResync();
        resyncRunnable = () -> {
            if (lastCommandCallback != null) {
                Log.d(TAG, "Auto-resync triggered after " + RESYNC_DELAY_MS + "ms");
                syncAcknowledged = false;
                shouldSyncAllRecords = false;
                startSyncTimeout();
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
