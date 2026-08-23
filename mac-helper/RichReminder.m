#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

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

static void copy_error(
    NSString *message,
    char *buffer,
    int bufferLength
) {
    if (!buffer || bufferLength <= 0) return;

    const char *utf8 = message.UTF8String ?: "Unknown error";
    snprintf(buffer, bufferLength, "%s", utf8);
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
