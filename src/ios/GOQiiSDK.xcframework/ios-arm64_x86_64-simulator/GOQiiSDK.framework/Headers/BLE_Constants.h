//
//  BLE_Constants.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//

typedef enum {
    pNone,
    pSyncingWithBand,
    pSyncingWithServer,
    pSynchingWithBandServer,
    pSendingDataToCoach,
    pWriteValuesToLocalDB,
    pSendingDataToCoachCompleted,
    pBAndConnecting,
    pBandConnected,
    pBandDisconnected,
    pBandBluetoothTurnedOff,
    pBandBluetoothTurnedOn,
    pBandNotLinked
    
}ProgressType;










//Constants
#define SCAN_TMEOUT       5
#define SEARCH_TIMEOUT    30
#define CONNECION_TIMEOUT 10
#define BIND_TIMEOUT      10
#define GET_MAC_TIMEOUT   10

//#define FETCH_SYNC_COUNT  15
#define RESYNC_COUNT      3
#define MAX_SYNC_COUNT    30
#define RE_SYNC_DAYS_COUNT    3
#define FT_SYNC_INCRE_COUNT 15
#define INCREMENTAL_SYNC_MINUTES [NSArray arrayWithObjects:@"16",@"31",@"46",@"01", nil]
#define INCREMENTAL_SYNC_SECOND @"01"



// UUID
#define GOQII_PROFILE_SERVICE_UUID      @"FFF0"
#define GOQII_MANUFACTURE_SERVICE_UUID  @"180A"
#define GOQII_TEMPRATURE_UUID           @"1809"


#define GOQII_TX_CHARACTERISTICS_UUID   @"FFF6"
#define GOQII_RX_CHARACTERISTICS_UUID   @"FFF7"

#define ACTIVE_PERIPHERAL_UUID          @"activePerpheralUUIS"
#define CLOUD_ACTIVE_PERIPHERAL_UUID          @"storedActivePerpheralUUIS"
#define ACTIVE_PERIPHERAL_MACID          @"activePerpheralMACID"

// Tracker and iPhone/iPad UUID device
#define CURRENT_DEVICE_UUID                  @"phoneUuid"
#define CLOUD_DEVICE_UUID                  @"storediPhoneUuid"



#define SERVICE   @"FFF0"
#define SEND_CHAR @"FFF6"
#define REC_CHAR  @"FFF7"
