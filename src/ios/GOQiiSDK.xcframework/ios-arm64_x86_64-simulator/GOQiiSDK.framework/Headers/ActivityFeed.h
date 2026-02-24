//
//  ActivityFeed.h
//  GOQii
//
//  Created by Prashant Thakur on 05/03/14.
//
//

#import <Foundation/Foundation.h>
@interface ActivityFeed : NSObject{
    
//    int feedId;
//    int serverFeedId;
//    int activityId;
//    int l_activityId;
//    NSString *activityText;
//    int likesCount;
//    int commentsCount;
//    NSString *imageUrl;
//    NSString *createdTime;
//    NSString *logDate;
//    NSString *feedType;
//    int caloriesBurnt;
//    NSString * intensity;
//    int screenType;
//    NSString *source;
}

@property int feedId;
@property int serverFeedId;
@property int activityId;
@property int l_activityId;
@property int feedIndex;
@property(nonatomic ,retain) NSString *activityText;
@property int likesCount;
@property int caloriesBurnt;
@property int steps;
@property int commentsCount;
@property(nonatomic ,retain) NSString *quantity;
@property(nonatomic ,retain) NSString *source;
@property(nonatomic ,retain) NSString *imageUrl;
@property(nonatomic ,retain) NSString *localImageUrl;
@property(nonatomic ,retain) NSString *createdTime;
@property(nonatomic ,retain) NSString *serverCreatedTime;
@property(nonatomic ,retain) NSString *logDate;
@property(nonatomic ,retain) NSString *feedType;
@property(nonatomic ,retain) NSString *subFeedType;
@property(nonatomic ,retain) NSString *discription;
@property(nonatomic ,retain) NSString *friendName;
@property(nonatomic ,retain) NSString *friendId;
@property(nonatomic ,retain) NSString *userImageUrl;
@property(nonatomic ,retain) NSString *isLikedByMe;
@property (assign,getter=isWorking) BOOL isCommentedByMe;
//@property(nonatomic ,retain) InternetImage *activityImageDownloadObject;
//@property(nonatomic ,retain) InternetImage *friendImageDownloadObject;
@property(nonatomic ,retain) NSString *intensity;
@property(nonatomic ,retain) NSString *privacyType;
@property(nonatomic ,retain) NSString *awakeTime;
@property(assign) int localIndex;
@property float distance;
@property float heightAspectRatio;
@property float imageWidth;
@property(nonatomic ,retain) NSString *profileType;
@property(nonatomic ,retain) NSString *causeId;
@property(nonatomic,retain)NSString *nutritionData;
@property(nonatomic,retain)NSString *feedImages;
@property(nonatomic,retain)NSString *tagDescription;
@property(nonatomic,retain)NSString *tagId;
@property(nonatomic,retain)NSString *videoList;

@property(nonatomic ,retain) NSString *fAI;
@property int fSN;
@property int fSSN;
@property int navigationType;
@property(nonatomic ,retain) NSString *fUI;
@property int blogRead;
@property(nonatomic ,retain) NSString *bookmarkedByMe;
@property int minsToRead;
@property Float32 feedHeight;
@property(nonatomic, retain) NSString *friendshipStatus;
@property(nonatomic, retain) NSString *jsonData;
@property(nonatomic, retain) NSDictionary *genericCardData;
@property(nonatomic,retain)NSString *additionalValue;
@property(nonatomic,retain)NSString *genericData;
@property (nonatomic, retain) NSString *logFrom,*heartData;
@property(nonatomic,retain)NSString *shareLink;
@property(nonatomic,retain)NSDictionary *feedUpdateObject;

// GPS activity feed
@property (nonatomic ,retain)NSString *gpsData, *gpsDerivedData,*simplifiedData,*unit;
@property(nonatomic, retain) NSString *healthAnalysis;
@property(nonatomic, retain) NSString *pointData;
@property(nonatomic, retain) NSString *profileBadge;
@property double maxPace,minPace,AvgPace,maxSpeed,avgSpeed,minSpeed,elevation;

+ (ActivityFeed *)sharedInstance;
-(void) setActivityFeed:(ActivityFeed *) feed;
-(id)initWithFeedData: (NSDictionary *)feedData;

@end
