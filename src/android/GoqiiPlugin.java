package com.goqii.goqiiplugin;

import android.content.Context;
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
    private GlucometerManager glucometerManager;
    private CallbackContext lastCommandCallback;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "execute: action = " + action);
        if(action != null && !action.equals("isGlucometerLinked") && !action.equals("setGlucometerMacId")){
            lastCommandCallback = callbackContext;
        }
        if (action.equals("initializeSDK")) {
            initializeGlucometer();
            return true;
        } else if (action.equals("searchGlucometer")) {
            glucometerManager.startScan();
            return true;
        } else if (action.equals("unlinkGlucometer")) {
            glucometerManager.unpairDevice();
            return true;
        } else if (action.equals("syncGlucometer")) {
            glucometerManager.syncGlucometer();
            return true;
        } else if (action.equals("connectGlucometer")) {
            glucometerManager.linkDevice();
            return true;
        } if(action.equals("isGlucometerLinked")){
            String mac = glucometerManager.getGlucometerMac();
            PluginResult pResult = new PluginResult(PluginResult.Status.OK, !TextUtils.isEmpty(mac));
            callbackContext.sendPluginResult(pResult);
            return true;
        }else if(action.equals("setGlucometerMacId")){
            if(args != null && args.length() != 0){
                String localMac = glucometerManager.getGlucometerMac();
                if(TextUtils.isEmpty(args.getString(0))){
                    try{
                        JSONObject result = new JSONObject();
                        result.put("message", "Pass MAC ID");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        callbackContext.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                    return true;
                }else if(!TextUtils.isEmpty(localMac) && !localMac.equals(args.getString(0))){
                    try{
                        JSONObject result = new JSONObject();
                        result.put("message", "Pass previously linked MAC ID");
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        callbackContext.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                    return true;
                }else {
                    glucometerManager.setGlucometerMacId(args.getString(0));
                    try{
                        JSONObject result = new JSONObject();
                        result.put("message", "MAC ID set successfully");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result.toString());
                        callbackContext.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                    return true;
                }
            }
            return true;
        }
        return false;
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
                        result.put("macId", macId);
                        result.put("message", "Device Linked");
                        result.put("name", deviceName);
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result.toString());
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
                        result.put("message", "Device Unlinked");
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result.toString());
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
                        result.put("message", "Device Link Failed");                    
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
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
                        result.put("message", "Device Unlink Failed");
                        // lastCommandCallback.error(result.toString());
                        
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult);
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onSyncComplete(String result) {
                    // lastCommandCallback.success(data);

                    PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                    pResult.setKeepCallback(true);
                    lastCommandCallback.sendPluginResult(pResult); 
                }

                @Override
                public void deviceNotFound() {
                try{  
                        JSONObject result = new JSONObject();
                        result.put("message", "Device Not Found");
                        // lastCommandCallback.error(result.toString());
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void onDeviceFound(String macId, String deviceName) {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("macId", macId);
                        result.put("name", deviceName);
                        result.put("message", "Device Found");
                        // lastCommandCallback.success(result.toString());
            
                        PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }

                @Override
                public void deviceNotPaired() {
                    try{
                        JSONObject result = new JSONObject();
                        result.put("message", "Device not paired please put device in the pairing mode");    
                        PluginResult pResult = new PluginResult(PluginResult.Status.ERROR, result.toString());
                        pResult.setKeepCallback(true);
                        lastCommandCallback.sendPluginResult(pResult); 
                    }catch(Exception e){
                        e.printStackTrace();
                    }
                }
            });
        }

        try{
            JSONObject result = new JSONObject();
            result.put("message", "Glucometer Initialized Successfully");
            result.put("glucometerLinked", glucometerManager.getGlucometerMac());
            // result.put("omronMac", glucometerManager.getOmronMac());

            // lastCommandCallback.success(result.toString());

            PluginResult pResult = new PluginResult(PluginResult.Status.OK, result);
            pResult.setKeepCallback(true);
            lastCommandCallback.sendPluginResult(pResult);
        }catch(Exception e){
            e.printStackTrace();
        }
    }
}
