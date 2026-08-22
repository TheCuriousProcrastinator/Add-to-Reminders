#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface REMObjectID : NSObject
+ (id)objectIDWithURL:(NSURL *)url;
@end

@interface REMStore : NSObject
- (id)fetchListWithObjectID:(id)objectID error:(NSError **)error;
@end

@interface REMSaveRequest : NSObject
- (instancetype)initWithStore:(REMStore *)store;
- (id)updateList:(id)list;
- (id)addReminderWithTitle:(NSString *)title
          toListChangeItem:(id)listChangeItem;
- (BOOL)saveSynchronouslyWithError:(NSError **)error;
@end

@interface REMRecurrenceDayOfWeek : NSObject
+ (id)dayOfWeek:(NSInteger)day;
+ (id)dayOfWeek:(NSInteger)day
     weekNumber:(NSInteger)weekNumber;
@end

@interface REMReminderChangeItem : NSObject
- (id)attachmentContext;
- (id)hashtagContext;
- (void)setNotesAsString:(NSString *)notes;
- (void)setPriority:(NSInteger)priority;
- (void)setDueDateComponents:(NSDateComponents *)components;
- (void)addRecurrenceRuleWithFrequency:(NSInteger)frequency
                              interval:(NSInteger)interval
                                   end:(id)end;

- (void)addRecurrenceRuleWithFrequency:(NSInteger)frequency
                              interval:(NSInteger)interval
                         daysOfTheWeek:(NSArray *)daysOfTheWeek
                       daysOfTheMonth:(NSArray *)daysOfTheMonth
                      monthsOfTheYear:(NSArray *)monthsOfTheYear
                       weeksOfTheYear:(NSArray *)weeksOfTheYear
                        daysOfTheYear:(NSArray *)daysOfTheYear
                         setPositions:(NSArray *)setPositions
                                  end:(id)end;
@end

@interface REMReminderAttachmentContextChangeItem : NSObject
- (id)addURLAttachmentWithURL:(NSURL *)url;

- (id)addImageAttachmentWithURL:(NSURL *)url
                          width:(NSUInteger)width
                         height:(NSUInteger)height
                          error:(NSError **)error;
@end

@interface REMReminderHashtagContextChangeItem : NSObject
- (id)addHashtagWithType:(NSInteger)type
                    name:(NSString *)name;
@end

static void copy_error(
    NSString *message,
    char *buffer,
    int bufferLength
) {
    if (!buffer || bufferLength <= 0) return;

    const char *utf8 = message.UTF8String ?: "Unknown error";
    snprintf(buffer, bufferLength, "%s", utf8);
}


int load_reminder_tags_json(
    char *jsonBuffer,
    int jsonBufferLength,
    char *errorBuffer,
    int errorBufferLength
) {
    @autoreleasepool {
        NSString *storesPath =
            [NSHomeDirectory()
                stringByAppendingPathComponent:
                    @"Library/Group Containers/group.com.apple.reminders/Container_v1/Stores"];

        NSError *directoryError = nil;

        NSArray<NSString *> *files =
            [[NSFileManager defaultManager]
                contentsOfDirectoryAtPath:storesPath
                error:&directoryError];

        if (!files) {
            copy_error(
                directoryError.localizedDescription
                    ?: @"Could not open Reminders data directory.",
                errorBuffer,
                errorBufferLength
            );
            return 1;
        }

        NSMutableDictionary<NSString *, NSString *> *tagsByKey =
            [NSMutableDictionary dictionary];

        BOOL queriedDatabase = NO;

        const char *sql =
            "SELECT DISTINCT "
            "COALESCE("
            "NULLIF(TRIM(ZNAME), ''), "
            "NULLIF(TRIM(ZCANONICALNAME), '')"
            ") "
            "FROM ZREMCDHASHTAGLABEL "
            "WHERE "
            "NULLIF(TRIM(ZNAME), '') IS NOT NULL "
            "OR "
            "NULLIF(TRIM(ZCANONICALNAME), '') IS NOT NULL "
            "ORDER BY 1 COLLATE NOCASE;";

        for (NSString *filename in files) {
            if (
                ![filename hasPrefix:@"Data-"] ||
                ![filename hasSuffix:@".sqlite"]
            ) {
                continue;
            }

            NSString *path =
                [storesPath
                    stringByAppendingPathComponent:
                        filename];

            sqlite3 *database = NULL;

            int openResult =
                sqlite3_open_v2(
                    path.fileSystemRepresentation,
                    &database,
                    SQLITE_OPEN_READONLY,
                    NULL
                );

            if (
                openResult != SQLITE_OK ||
                !database
            ) {
                if (database) {
                    sqlite3_close(database);
                }

                continue;
            }

            sqlite3_stmt *statement = NULL;

            int prepareResult =
                sqlite3_prepare_v2(
                    database,
                    sql,
                    -1,
                    &statement,
                    NULL
                );

            if (prepareResult != SQLITE_OK) {
                if (statement) {
                    sqlite3_finalize(statement);
                }

                sqlite3_close(database);
                continue;
            }

            queriedDatabase = YES;

            while (
                sqlite3_step(statement) ==
                SQLITE_ROW
            ) {
                const unsigned char *value =
                    sqlite3_column_text(
                        statement,
                        0
                    );

                if (!value) {
                    continue;
                }

                NSString *name =
                    [NSString
                        stringWithUTF8String:
                            (const char *)value];

                name =
                    [name
                        stringByTrimmingCharactersInSet:
                            NSCharacterSet
                                .whitespaceAndNewlineCharacterSet];

                if (name.length == 0) {
                    continue;
                }

                tagsByKey[
                    name.lowercaseString
                ] = name;
            }

            sqlite3_finalize(statement);
            sqlite3_close(database);
        }

        if (!queriedDatabase) {
            copy_error(
                @"Could not read the Reminders tag database.",
                errorBuffer,
                errorBufferLength
            );
            return 1;
        }

        NSArray<NSString *> *tags =
            [tagsByKey.allValues
                sortedArrayUsingSelector:
                    @selector(
                        localizedCaseInsensitiveCompare:
                    )];

        NSError *jsonError = nil;

        NSData *jsonData =
            [NSJSONSerialization
                dataWithJSONObject:tags
                options:0
                error:&jsonError];

        if (!jsonData) {
            copy_error(
                jsonError.localizedDescription
                    ?: @"Could not encode Reminders tags.",
                errorBuffer,
                errorBufferLength
            );
            return 1;
        }

        NSString *json =
            [[NSString alloc]
                initWithData:jsonData
                encoding:NSUTF8StringEncoding];

        const char *utf8 =
            json.UTF8String ?: "[]";

        if (
            strlen(utf8) + 1 >
            (size_t)jsonBufferLength
        ) {
            copy_error(
                @"Reminders tag catalog is too large.",
                errorBuffer,
                errorBufferLength
            );
            return 1;
        }

        snprintf(
            jsonBuffer,
            jsonBufferLength,
            "%s",
            utf8
        );

        return 0;
    }
}

int add_rich_reminder(
    const char *listIDCString,
    const char *titleCString,
    const char *urlCString,
    const char *imageURLCString,
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int hasTime,
    int recurrenceFrequency,
    int recurrenceInterval,
    const char *recurrenceJSONCString,
    int priority,
    const char *notesCString,
    const char *tagsJSONCString,
    char *errorBuffer,
    int errorBufferLength
) {
    @autoreleasepool {
        NSString *listID =
            [NSString stringWithUTF8String:listIDCString ?: ""];

        NSString *title =
            [NSString stringWithUTF8String:titleCString ?: ""];

        NSString *urlString =
            [NSString stringWithUTF8String:urlCString ?: ""];

        NSString *imageURLString =
            [NSString stringWithUTF8String:imageURLCString ?: ""];

        NSString *notes =
            [NSString stringWithUTF8String:notesCString ?: ""];

        NSString *tagsJSON =
            [NSString stringWithUTF8String:tagsJSONCString ?: "[]"];

        NSArray *tagNames = @[];

        if (tagsJSON.length > 0) {
            NSData *tagData =
                [tagsJSON dataUsingEncoding:NSUTF8StringEncoding];

            NSError *tagJSONError = nil;

            id tagObject =
                [NSJSONSerialization
                    JSONObjectWithData:tagData
                    options:0
                    error:&tagJSONError];

            if (
                tagJSONError ||
                ![tagObject isKindOfClass:[NSArray class]]
            ) {
                copy_error(
                    @"Invalid tags payload.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            tagNames =
                (NSArray *)tagObject;
        }

        if (listID.length == 0 || title.length == 0) {
            copy_error(
                @"Missing list or title.",
                errorBuffer,
                errorBufferLength
            );
            return 1;
        }

        NSString *objectURLString =
            [NSString stringWithFormat:
                @"x-apple-reminderkit://REMCDList/%@",
                listID
            ];

        NSURL *objectURL =
            [NSURL URLWithString:objectURLString];

        id objectID =
            [REMObjectID objectIDWithURL:objectURL];

        NSError *error = nil;
        REMStore *store = [REMStore new];

        id list =
            [store fetchListWithObjectID:objectID
                                   error:&error];

        if (!list) {
            copy_error(
                error.localizedDescription ?: @"Reminder list not found.",
                errorBuffer,
                errorBufferLength
            );
            return 2;
        }

        REMSaveRequest *save =
            [[REMSaveRequest alloc] initWithStore:store];

        id listChange = [save updateList:list];

        if (!listChange) {
            copy_error(
                @"Could not prepare Reminders list.",
                errorBuffer,
                errorBufferLength
            );
            return 3;
        }

        REMReminderChangeItem *reminder =
            [save addReminderWithTitle:title
                      toListChangeItem:listChange];

        if (!reminder) {
            copy_error(
                @"Could not create reminder.",
                errorBuffer,
                errorBufferLength
            );
            return 4;
        }

        if (year > 0 && month > 0 && day > 0) {
            NSDateComponents *components =
                [[NSDateComponents alloc] init];

            components.calendar = [NSCalendar currentCalendar];
            components.timeZone = [NSTimeZone localTimeZone];
            components.year = year;
            components.month = month;
            components.day = day;

            if (hasTime) {
                components.hour = hour;
                components.minute = minute;
            }

            [reminder setDueDateComponents:components];
        }

        if (notes.length > 0) {
            [reminder setNotesAsString:notes];
        }

        [reminder setPriority:priority];

        if (recurrenceFrequency >= 0) {
            NSInteger interval =
                recurrenceInterval > 0
                    ? recurrenceInterval
                    : 1;

            NSMutableArray *daysOfWeek =
                [NSMutableArray array];

            if (recurrenceJSONCString) {
                NSString *jsonString =
                    [NSString stringWithUTF8String:
                        recurrenceJSONCString
                    ];

                NSData *jsonData =
                    [jsonString
                        dataUsingEncoding:
                            NSUTF8StringEncoding
                    ];

                if (jsonData.length > 0) {
                    NSDictionary *recurrence =
                        [NSJSONSerialization
                            JSONObjectWithData:jsonData
                            options:0
                            error:nil
                        ];

                    NSArray *rawDays =
                        recurrence[@"weekdays"];

                    if (
                        [rawDays
                            isKindOfClass:
                                [NSArray class]
                        ]
                    ) {
                        for (id raw in rawDays) {

                            if (
                                [raw
                                    isKindOfClass:
                                        [NSNumber class]
                                ]
                            ) {
                                NSInteger day =
                                    [raw integerValue];

                                if (
                                    day >= 1 &&
                                    day <= 7
                                ) {
                                    [daysOfWeek addObject:
                                        [REMRecurrenceDayOfWeek
                                            dayOfWeek:day
                                        ]
                                    ];
                                }

                            } else if (
                                [raw
                                    isKindOfClass:
                                        [NSDictionary class]
                                ]
                            ) {
                                NSInteger day =
                                    [raw[@"day"]
                                        integerValue];

                                NSInteger weekNumber =
                                    [raw[@"weekNumber"]
                                        integerValue];

                                if (
                                    day >= 1 &&
                                    day <= 7
                                ) {
                                    [daysOfWeek addObject:
                                        [REMRecurrenceDayOfWeek
                                            dayOfWeek:day
                                            weekNumber:weekNumber
                                        ]
                                    ];
                                }
                            }
                        }
                    }
                }
            }

            if (daysOfWeek.count > 0) {
                [reminder
                    addRecurrenceRuleWithFrequency:recurrenceFrequency
                    interval:interval
                    daysOfTheWeek:daysOfWeek
                    daysOfTheMonth:nil
                    monthsOfTheYear:nil
                    weeksOfTheYear:nil
                    daysOfTheYear:nil
                    setPositions:nil
                    end:nil
                ];

            } else {
                [reminder
                    addRecurrenceRuleWithFrequency:recurrenceFrequency
                    interval:interval
                    end:nil
                ];
            }
        }

        if (tagNames.count > 0) {
            REMReminderHashtagContextChangeItem *hashtagContext =
                [reminder hashtagContext];

            if (!hashtagContext) {
                copy_error(
                    @"Could not create Reminders hashtag context.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSMutableSet<NSString *> *seenTags =
                [NSMutableSet set];

            for (id value in tagNames) {
                if (![value isKindOfClass:[NSString class]]) {
                    continue;
                }

                NSString *name =
                    [(NSString *)value
                        stringByTrimmingCharactersInSet:
                            NSCharacterSet.whitespaceAndNewlineCharacterSet];

                if (name.length == 0) {
                    continue;
                }

                NSString *key =
                    name.lowercaseString;

                if ([seenTags containsObject:key]) {
                    continue;
                }

                [seenTags addObject:key];

                [hashtagContext
                    addHashtagWithType:1
                    name:name];
            }
        }

        REMReminderAttachmentContextChangeItem *attachmentContext =
            [reminder attachmentContext];

        if (imageURLString.length > 0) {
            NSURL *remoteImageURL =
                [NSURL URLWithString:imageURLString];

            if (!remoteImageURL) {
                copy_error(
                    @"Invalid image URL.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            if (
                [remoteImageURL.scheme
                    caseInsensitiveCompare:@"blob"]
                    == NSOrderedSame
            ) {
                copy_error(
                    @"This image uses a browser-only blob URL and cannot be downloaded directly.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSError *downloadError = nil;

            NSData *imageData =
                [NSData
                    dataWithContentsOfURL:remoteImageURL
                    options:0
                    error:&downloadError];

            if (!imageData) {
                NSString *message =
                    [NSString stringWithFormat:
                        @"Could not download image: %@",
                        downloadError.localizedDescription
                            ?: @"Unknown error"
                    ];

                copy_error(
                    message,
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            const NSUInteger maximumImageBytes =
                20 * 1024 * 1024;

            if (
                imageData.length >
                maximumImageBytes
            ) {
                copy_error(
                    @"Image is larger than 20 MB.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSImage *image =
                [[NSImage alloc]
                    initWithData:imageData];

            if (!image) {
                copy_error(
                    @"The downloaded file is not a supported image.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSSize size =
                image.size;

            if (
                size.width <= 0 ||
                size.height <= 0
            ) {
                copy_error(
                    @"Could not determine image dimensions.",
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSString *extension =
                remoteImageURL.pathExtension;

            if (extension.length == 0) {
                extension = @"img";
            }

            NSString *tempFilename =
                [NSString stringWithFormat:
                    @"add-to-reminders-%@.%@",
                    NSUUID.UUID.UUIDString,
                    extension
                ];

            NSString *tempPath =
                [NSTemporaryDirectory()
                    stringByAppendingPathComponent:
                        tempFilename];

            NSURL *tempURL =
                [NSURL fileURLWithPath:
                    tempPath];

            NSError *writeError = nil;

            BOOL wroteFile =
                [imageData
                    writeToURL:tempURL
                    options:NSDataWritingAtomic
                    error:&writeError];

            if (!wroteFile) {
                NSString *message =
                    [NSString stringWithFormat:
                        @"Could not prepare image attachment: %@",
                        writeError.localizedDescription
                            ?: @"Unknown error"
                    ];

                copy_error(
                    message,
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }

            NSError *attachmentError = nil;

            NSUInteger imageWidth =
                MAX(
                    (NSUInteger)1,
                    (NSUInteger)size.width
                );

            NSUInteger imageHeight =
                MAX(
                    (NSUInteger)1,
                    (NSUInteger)size.height
                );

            id imageAttachment =
                [attachmentContext
                    addImageAttachmentWithURL:tempURL
                    width:imageWidth
                    height:imageHeight
                    error:&attachmentError];

            if (
                !imageAttachment &&
                !attachmentError
            ) {
                attachmentError =
                    [NSError
                        errorWithDomain:@"AddToReminders"
                        code:1
                        userInfo:@{
                            NSLocalizedDescriptionKey:
                                @"ReminderKit did not create the image attachment."
                        }];
            }

            if (attachmentError) {
                NSString *message =
                    [NSString stringWithFormat:
                        @"Could not attach image: %@",
                        attachmentError.localizedDescription
                            ?: @"Unknown error"
                    ];

                copy_error(
                    message,
                    errorBuffer,
                    errorBufferLength
                );
                return 1;
            }
        }

        if (urlString.length > 0) {
            NSURL *website = [NSURL URLWithString:urlString];

            if (website) {


                if (!attachmentContext) {
                    copy_error(
                        @"Could not create URL attachment context.",
                        errorBuffer,
                        errorBufferLength
                    );
                    return 5;
                }

                [attachmentContext
                    addURLAttachmentWithURL:website];
            }
        }

        error = nil;

        if (![save saveSynchronouslyWithError:&error]) {
            copy_error(
                error.localizedDescription ?: @"Could not save reminder.",
                errorBuffer,
                errorBufferLength
            );
            return 6;
        }

        return 0;
    }
}
