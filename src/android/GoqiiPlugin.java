package com.goqii.goqiiplugin;

import android.content.Context;
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
    private GlucometerManager glucometerManager;
    private CallbackContext eventCallback; // Single, persistent callback for async events

    private enum EventType {
        INITIALIZED,
        DEVICE_FOUND,
        DEVICE_LINKED,
        DEVICE_UNLINKED,
        LINK_FAILED,
        UNLINK_FAILED,
        SYNC_COMPLETE,
        DEVICE_NOT_FOUND,
        DEVICE_NOT_PAIRED,
        ERROR
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "initialize":
                initialize(callbackContext);
                return true;
            case "registerEventListener":
                // This will be our single point of contact for all async events
                this.eventCallback = callbackContext;
                return true;
            case "searchGlucometer":
                 if (glucometerManager == null) {
                        callbackContext.error("SDK not initialized. Please call initialize() first.");
                        return true; // Still return true as we've handled the action
                    }
                glucometerManager.startScan();
                callbackContext.success("Action initiated.");
                return true;
            
            case "connectGlucometer":
                if (glucometerManager == null) {
                        callbackContext.error("SDK not initialized. Please call initialize() first.");
                        return true; // Still return true as we've handled the action
                    }
                glucometerManager.linkDevice();
                callbackContext.success("Action initiated.");
                return true;
            case "syncGlucometer":
                if (glucometerManager == null) {
                        callbackContext.error("SDK not initialized. Please call initialize() first.");
                        return true; // Still return true as we've handled the action
                    }
                glucometerManager.syncGlucometer();
                callbackContext.success("Action initiated.");
                return true;
            case "unlinkGlucometer":
                if (glucometerManager == null) {
                        callbackContext.error("SDK not initialized. Please call initialize() first.");
                        return true; // Still return true as we've handled the action
                    }
                glucometerManager.unpairDevice();
                callbackContext.success("Action initiated.");
                return true;
            case "isGlucometerLinked":
                isGlucometerLinked(callbackContext);
                return true;
            case "setGlucometerMacId":
                setGlucometerMacId(args.getString(0), callbackContext);
                return true;
            default:
                return false;
        }
    }

    private void initialize(CallbackContext callbackContext) {
        if (glucometerManager != null) {
            callbackContext.success("SDK already initialized.");
            return;
        }

            Context context = cordova.getActivity();
            glucometerManager = new GlucometerManager(context, new GlucometerManager.GlucometerListener() {
                @Override
                public void onDeviceFound(String macId, String deviceName) {
                    sendEvent(EventType.DEVICE_FOUND, "macId", macId, "name", deviceName);
                }

                @Override
                public void onDeviceLinked(String macId, String deviceName) {
                    sendEvent(EventType.DEVICE_LINKED, "macId", macId, "name", deviceName);
                }

                @Override
                public void onDeviceUnlinked(String macId) {
                    sendEvent(EventType.DEVICE_UNLINKED, "macId", macId);
                }

                @Override
                public void onDeviceLinkFailed() {
                    sendEvent(EventType.LINK_FAILED);
                }

                @Override
                public void onDeviceUnlinkFailed() {
                    sendEvent(EventType.UNLINK_FAILED);
                }

                @Override
                public void onSyncComplete(String result) {
                    // Assuming 'result' is a JSON string from the SDK, we parse it
                    try {
                        sendEvent(EventType.SYNC_COMPLETE, "data", new JSONObject(result));
                    } catch (JSONException e) {
                        sendErrorEvent("Failed to parse sync data.", e);
                    }
                }

                @Override
                public void deviceNotFound() {
                    sendEvent(EventType.DEVICE_NOT_FOUND);
                }

                @Override
                public void deviceNotPaired() {
                    sendEvent(EventType.DEVICE_NOT_PAIRED);
                }
           

            // Send an initialized event to confirm setup is complete
            sendEvent(EventType.INITIALIZED, "isLinked", !TextUtils.isEmpty(glucometerManager.getGlucometerMac()));
            callbackContext.success("SDK Initialized Successfully");
        });
    }

    private void isGlucometerLinked(CallbackContext callbackContext) {
        if (glucometerManager == null) {
            callbackContext.error("SDK not initialized.");
            return;
        }
        boolean isLinked = !TextUtils.isEmpty(glucometerManager.getGlucometerMac());
        PluginResult result = new PluginResult(PluginResult.Status.OK, isLinked);
        callbackContext.sendPluginResult(result);
    }

    private void setGlucometerMacId(String macId, CallbackContext callbackContext) {
        if (glucometerManager == null) {
            callbackContext.error("SDK not initialized.");
            return;
        }

        if (TextUtils.isEmpty(macId)) {
            callbackContext.error("MAC ID cannot be empty.");
            return;
        }

        String existingMac = glucometerManager.getGlucometerMac();
        if (!TextUtils.isEmpty(existingMac) && !existingMac.equalsIgnoreCase(macId)) {
            callbackContext.error("A different MAC ID is already linked. Unlink first.");
            return;
        }

        glucometerManager.setGlucometerMacId(macId);
        callbackContext.success("MAC ID set successfully.");
    }

    private boolean executeSdkAction(java.lang.Runnable action, CallbackContext callbackContext) {
        if (glucometerManager == null) {
            callbackContext.error("SDK not initialized. Please call initialize() first.");
            return true; // Still return true as we've handled the action
        }
        // Execute the action on a background thread to avoid blocking the main UI thread.
        cordova.getActivity().runOnUiThread(action);
        callbackContext.success("Action initiated.");
        return true;
    }

    // --- Unified Event Emitter ---

    private void sendEvent(EventType type, Object... keyValuePairs) {
        JSONObject payload = new JSONObject();
        try {
            for (int i = 0; i < keyValuePairs.length; i += 2) {
                String key = (String) keyValuePairs[i];
                Object value = keyValuePairs[i + 1];
                payload.put(key, value);
            }
        } catch (JSONException e) {
            Log.e(TAG, "Failed to create event payload", e);
            sendErrorEvent("Failed to create event payload", e);
            return;
        }
        sendEvent(type, payload);
    }

    private void sendEvent(EventType type, JSONObject payload) {
        if (this.eventCallback == null) {
            Log.w(TAG, "eventCallback is not registered. Cannot send event: " + type.name());
            return;
        }

        try {
            JSONObject event = new JSONObject();
            event.put("type", type.name());
            event.put("payload", payload);

            PluginResult result = new PluginResult(PluginResult.Status.OK, event);
            result.setKeepCallback(true); // Keep the callback alive for future events
            this.eventCallback.sendPluginResult(result);
        } catch (JSONException e) {
            Log.e(TAG, "Failed to construct event object", e);
        }
    }

    private void sendErrorEvent(String message, Exception e) {
        Log.e(TAG, message, e);
        JSONObject errorPayload = new JSONObject();
        try {
            errorPayload.put("errorMessage", message);
            if (e != null) {
                errorPayload.put("exception", e.getMessage());
            }
        } catch (JSONException je) {
            Log.e(TAG, "Failed to create error payload", je);
        }
        sendEvent(EventType.ERROR, errorPayload);
    }
}
