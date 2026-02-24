
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//DATE TYPE FORMATS
 static NSString* DATE_TYPE_YYYY_MM_DD = @"yyyy-MM-dd";
 static NSString* DATE_TYPE_YYYY_MM_DD_HH_MM_SS = @"yyyy-MM-dd HH:mm:ss";
 static NSString* DATE_TYPE_YYYY_MM_DD_HH_MM_SS_SSS = @"yyyy-MM-dd HH:mm:ss.sss";
 static NSString* DATE_TYPE_YYYY_MM_DD_HH_MM_SS_AA = @"yyyy-MM-dd HH:mm:ss aa";
 static  NSString* DATE_TYPE_YYYY_MM_DD_HH_MM_AA = @"yyyy-MM-dd HH:mm aa";
static  NSString* DATE_TYPE_YYYY_MM_DD_HH_MM = @"yyyy-MM-dd HH:mm";
static NSString* DATE_TYPE_DD_MMM_YYYY_HH_MM_AA = @"d MMM yyyy, hh:mm a";
// static NSString* DATE_TYPE_DD_MMM_YYYY = @"dd-MMM-yyyy";
 static NSString* DATE_TYPE_MMM_DD_YYYY = @"MMM-dd-yyyy";
 static NSString* DATE_TYPE_DD_MMM_YYYY = @"d MMM yyyy";

static NSString* DATE_TYPE_MMM_YYYY = @"MMM yyyy";
static NSString* DATE_TYPE_YYYY_MM = @"yyyy-MM";
static NSString* DATE_TYPE_YYYY = @"yyyy";

 static NSString* DATE_TYPE_DD_MMM = @"d MMM";
static NSString* DATE_TYPE_MMM_DD = @"MMM d";
static NSString* DATE_TYPE_MMM = @"MMM";

static NSString* TIME_TYPE_hh_mm_a  = @"h:mm a";
static NSString* TIME_TYPE_HH_mm  = @"HH:mm";
static NSString* TIME_TYPE_HH_mm_ss  = @"HH:mm:ss";
static NSString* TIME_TYPE_mm_ss  = @"mm:ss";

typedef struct
{
    uint8_t mseconds;
    uint8_t seconds;  // 0-59
    uint8_t minutes;  // 0-59
    uint8_t hour;     // 0-23
    uint8_t day;      // 0-30
    uint8_t month;    // 0-11
    uint8_t weekdays;
    uint16_t year;    // 2000+
} UTCTimeStruct;
//@interface Calender : NSObject
//
//@end


@interface NSDate (Utils)

+(NSString *)ConvertUTCTime:(long)secTime;

+ (NSDate *)dateWithYear:(NSInteger)year
                   month:(NSInteger)month
                     day:(NSInteger)day
                    hour:(NSInteger)hour
                  minute:(NSInteger)minute
                  second:(NSInteger)second;

+ (NSInteger)daysOffsetBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSDate *)dateWithHour:(int)hour
                  minute:(int)minute;

#pragma mark - Getter
- (NSInteger)year;
- (NSInteger)month;
- (NSInteger)day;
- (NSInteger)hour;
- (NSInteger)minute;
- (NSInteger)second;
- (NSString *)weekday;

#pragma mark -- formatter
+ (NSDateFormatter *)formatter;

#pragma mark - Time string
- (NSString *)timeHourMinute;
- (NSString *)timeHourMinuteWithPrefix;
- (NSString *)timeHourMinuteWithSuffix;
- (NSString *)timeHourMinuteWithPrefix:(BOOL)enablePrefix suffix:(BOOL)enableSuffix;

#pragma mark - Date String
- (NSString *)stringTime;
- (NSString *)stringTimeCustom;
- (NSString *)stringMonthDay;
- (NSString *)stringYearMonthDay;
- (NSString *)stringDayMonthYear;
- (NSString *)stringYearMonthDayHourMinuteCustom;
- (NSString *)stringMonthDayHourMinuteCustom;
- (NSString *)stringYearMonthDayHourMinuteSecond;
- (NSString *)stringWithFormat:(NSString *)newFormat;
+ (NSString *)stringYearMonthDayWithDate:(NSDate *)date;
+ (NSString *)stringLoacalDate;

#pragma mark - Date formate
+ (NSString *)dateFormatString;
+ (NSString *)timeFormatString;
+ (NSString *)timestampFormatString;
+ (NSString *)timestampFormatStringSubSeconds;

#pragma mark - Date adjust
- (NSDate *) dateByAddingDays: (NSInteger) dDays;
- (NSDate *) dateBySubtractingDays: (NSInteger) dDays;
+(NSString *)subtractDaysFromGivenDate:(NSString *)givenDate withDaysCount:(int)count;

#pragma mark - Relative dates from the date
+ (NSDate *) dateTomorrow;
+ (NSDate *) dateYesterday;
+ (NSDate *) dateWithDaysFromNow: (NSInteger) days;
+ (NSDate *) dateWithDaysBeforeNow: (NSInteger) days;
+ (NSDate *) dateWithHoursFromNow: (NSInteger) dHours;
+ (NSDate *) dateWithHoursBeforeNow: (NSInteger) dHours;
+ (NSDate *) dateWithMinutesFromNow: (NSInteger) dMinutes;
+ (NSDate *) dateWithMinutesBeforeNow: (NSInteger) dMinutes;
+ (NSDate *) dateStandardFormatTimeZeroWithDate: (NSDate *) aDate;
- (NSInteger) daysBetweenCurrentDateAndDate;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (NSInteger)yearsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

#pragma mark - Date compare
- (BOOL)isEqualToDateIgnoringTime: (NSDate *) aDate;
- (NSString *)stringYearMonthDayCompareToday;

#pragma mark - Date and string convert
+ (NSDate *)dateFromString:(NSString *)string;
+ (NSDate *)dateFromString:(NSString *)string withFormat:(NSString *)format;
+ (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format;
+ (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format forLocal:(NSLocale *) locale;
- (NSString *)string;
- (NSString *)stringCutSeconds;

+(NSString*)timeLeftSinceDate:(NSDate *)date;
+(NSString*)daysLeftSinceDate:(NSDate *)date;
+(NSInteger)differenceTime:(NSDate *)date;
+(NSString *)get24HoursTimeStringFor:(NSString *)actualTime;
+(NSString *)get12HoursTimeStringFor:(NSString *)actualTime;
+(NSString*)getRequiredTimeFormat:(NSString*)actualTime;
+(NSString*)getRequiredDateFormat:(NSString*)actualDate;
+(NSString*)getMonthFromDate:(NSDate*)actualDate;
+(NSString*)getYearFromDate:(NSDate*)actualDate;
+(BOOL)isCurrentYear:(NSDate *)actualDate;
+ (NSString *)stringFromDateString:(NSString *)dateString withOldFormat:(NSString *)oldFormat andNewFormat:(NSString *)newFormat forLocal:(NSLocale *) locale;
+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

-(NSDate *) firstDateofMonth;
-(NSDate *) lastDateofMonth;

-(int) getOffSetForDateTime;

-(BOOL) isLaterThanOrEqualTo:(NSDate*)date;
-(BOOL) isEarlierThanOrEqualTo:(NSDate*)date;
-(BOOL) isLaterThan:(NSDate*)date;
-(BOOL) isEarlierThan:(NSDate*)date;

+(NSString *)get12HoursTimeString2For:(NSString *)actualTime;
+(NSString *)get24HoursTimeString2For:(NSString *)actualTime;
+(NSDate*)getDateFromString:(NSString *)stringDate;
@end
