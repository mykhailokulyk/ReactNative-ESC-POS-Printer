#import "EscPosPrinter.h"
#import "ErrorManager.h"

@interface EscPosPrinter() <Epos2PtrReceiveDelegate, Epos2PrinterSettingDelegate>
 @property (strong, nonatomic) NSString* printerAddress;
@end

@implementation EscPosPrinter

#define DISCONNECT_INTERVAL                  0.5

RCT_EXPORT_MODULE()

- (id)init {
    self = [super init];
    if (self) {
         tasksQueue = [[NSOperationQueue alloc] init];
         tasksQueue.maxConcurrentOperationCount = 1;

    }

    return  self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onPrintSuccess", @"onPrintFailure", @"onGetPaperWidthSuccess", @"onGetPaperWidthFailure", @"onMonitorStatusUpdate"];
}

- (NSDictionary *)constantsToExport
{
 return @{
      @"EPOS2_TM_M10": @(EPOS2_TM_M10),
      @"EPOS2_TM_M30": @(EPOS2_TM_M30),
      @"EPOS2_TM_P20": @(EPOS2_TM_P20),
      @"EPOS2_TM_P60": @(EPOS2_TM_P60),
      @"EPOS2_TM_P60II": @(EPOS2_TM_P60II),
      @"EPOS2_TM_P80": @(EPOS2_TM_P80),
      @"EPOS2_TM_T20": @(EPOS2_TM_T20),
      @"EPOS2_TM_T60": @(EPOS2_TM_T60),
      @"EPOS2_TM_T70": @(EPOS2_TM_T70),
      @"EPOS2_TM_T81": @(EPOS2_TM_T81),
      @"EPOS2_TM_T82": @(EPOS2_TM_T82),
      @"EPOS2_TM_T83": @(EPOS2_TM_T83),
      @"EPOS2_TM_T88": @(EPOS2_TM_T88),
      @"EPOS2_TM_T90": @(EPOS2_TM_T90),
      @"EPOS2_TM_T90KP": @(EPOS2_TM_T90KP),
      @"EPOS2_TM_U220": @(EPOS2_TM_U220),
      @"EPOS2_TM_U330": @(EPOS2_TM_U330),
      @"EPOS2_TM_L90": @(EPOS2_TM_L90),
      @"EPOS2_TM_H6000": @(EPOS2_TM_H6000),
      @"EPOS2_TM_T83III": @(EPOS2_TM_T83III),
      @"EPOS2_TM_T100": @(EPOS2_TM_T100),
      @"EPOS2_TM_M30II": @(EPOS2_TM_M30II),
      @"EPOS2_TS_100": @(EPOS2_TS_100),
      @"EPOS2_TM_M50": @(EPOS2_TM_M50),
      @"COMMAND_ADD_TEXT": @(COMMAND_ADD_TEXT),
      @"COMMAND_ADD_NEW_LINE": @(COMMAND_ADD_NEW_LINE),
      @"COMMAND_ADD_TEXT_STYLE": @(COMMAND_ADD_TEXT_STYLE),
      @"COMMAND_ADD_TEXT_SIZE": @(COMMAND_ADD_TEXT_SIZE),
      @"COMMAND_ADD_ALIGN": @(COMMAND_ADD_ALIGN),
      @"COMMAND_ADD_IMAGE": @(COMMAND_ADD_IMAGE),
      @"COMMAND_ADD_CUT": @(COMMAND_ADD_CUT),
      @"EPOS2_ALIGN_LEFT": @(EPOS2_ALIGN_LEFT),
      @"EPOS2_ALIGN_RIGHT": @(EPOS2_ALIGN_RIGHT),
      @"EPOS2_ALIGN_CENTER": @(EPOS2_ALIGN_CENTER),
      @"EPOS2_TRUE": @(EPOS2_TRUE),
      @"EPOS2_FALSE": @(EPOS2_FALSE),
   };
}

enum PrintingCommands : int {
    COMMAND_ADD_TEXT = 0,
    COMMAND_ADD_NEW_LINE,
    COMMAND_ADD_TEXT_STYLE,
    COMMAND_ADD_TEXT_SIZE,
    COMMAND_ADD_ALIGN,
    COMMAND_ADD_IMAGE,
    COMMAND_ADD_CUT,
};

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

RCT_EXPORT_METHOD(init:(NSString *)target
                  series:(int)series
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
    [self finalizeObject];
    [self initializeObject: series onSuccess:^(NSString *result) {
        resolve(result);
    } onError:^(NSString *error) {
       reject(@"event_failure",error, nil);

    }];

    self.printerAddress = target;
}

RCT_EXPORT_METHOD(printBase64: (NSString *)base64string
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
 [tasksQueue addOperationWithBlock: ^{
    [self printFromBase64:base64string onSuccess:^(NSString *result) {
            resolve(result);
        } onError:^(NSString *error) {
            reject(@"event_failure",error, nil);
    }];
  }];
}

RCT_EXPORT_METHOD(getPaperWidth:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
  [tasksQueue addOperationWithBlock: ^{
    [self getPrinterSettings:EPOS2_PRINTER_SETTING_PAPERWIDTH onSuccess:^(NSString *result) {
            resolve(result);
        } onError:^(NSString *error) {
            reject(@"event_failure",error, nil);
    }];
  }];
}


RCT_EXPORT_METHOD(pairingBluetoothPrinter:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
    [self pairingBluetoothPrinter:^(NSString *result) {
            resolve(result);
        } onError:^(NSString *error) {
            reject(@"event_failure",error, nil);
    }];
}

RCT_EXPORT_METHOD(disconnect)
{
    [self disconnectPrinter];
}

RCT_EXPORT_METHOD(startMonitorPrinter:(int) interval
                  withResolver: (RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{

    [self startMonitorPrinter:interval onSuccess:^(NSString *result) {
            resolve(result);
        } onError:^(NSString *error) {
            reject(@"event_failure",error, nil);
    }];
}

RCT_EXPORT_METHOD(stopMonitorPrinter:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
    [self stopMonitorPrinter:^(NSString *result) {
            resolve(result);
        } onError:^(NSString *error) {
            reject(@"event_failure",error, nil);
    }];
}


RCT_EXPORT_METHOD(printBuffer: (NSArray *)printBuffer
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
{
    [tasksQueue addOperationWithBlock: ^{
        [self printFromBuffer:printBuffer onSuccess:^(NSString *result) {
                resolve(result);
            } onError:^(NSString *error) {
                reject(@"event_failure",error, nil);
        }];
    }];
}



- (void) onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId
{
    NSString *result = [ErrorManager getEposResultText: code];
    if (code == EPOS2_CODE_SUCCESS) {
      NSDictionary *msg = [ErrorManager makeStatusMessage: status];
      [self sendEventWithName:@"onPrintSuccess" body: msg];
    }
    else {
      [self sendEventWithName:@"onPrintFailure" body: result];
    }

    [self performSelectorInBackground:@selector(disconnectPrinter) withObject:nil];
}

- (void) onGetPrinterSetting: (int)code type:(int)type value:(int)value
{
   NSString *result = [ErrorManager getEposResultText: code];

  if(code == EPOS2_CODE_SUCCESS) {
    if(type == EPOS2_PRINTER_SETTING_PAPERWIDTH) {
       int paperWidth = [ErrorManager getEposGetWidthResult: value];
       [self sendEventWithName:@"onGetPaperWidthSuccess" body: @(paperWidth)];
    }
  } else {
    if(type == EPOS2_PRINTER_SETTING_PAPERWIDTH) {
       [self sendEventWithName:@"onGetPaperWidthFailure" body: result];
    }
  }

  [self performSelectorInBackground:@selector(disconnectPrinter) withObject:nil];
}



// Methods

- (int)printData
{

    int result = [self connectPrinter];

    if (result != EPOS2_SUCCESS) {
        [printer clearCommandBuffer];
        return result;
    }



    result = [printer sendData:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        [printer clearCommandBuffer];
        [printer disconnect];
        return result;
    }

    return result;

}


- (void)initializeObject: (int)series
                          onSuccess: (void(^)(NSString *))onSuccess
                          onError: (void(^)(NSString *))onError
{
    printer = nil;
    PrinterInfo* printerInfo = [PrinterInfo sharedPrinterInfo];
    printerInfo.printerSeries = series;
    printerInfo.lang = EPOS2_MODEL_ANK;

    printer = [[Epos2Printer alloc] initWithPrinterSeries:printerInfo.printerSeries lang:printerInfo.lang];

    if (printer == nil) {
        NSString *errorString = [ErrorManager getEposErrorText: EPOS2_ERR_PARAM];
        onError(errorString);
        return;
    }

    [printer setReceiveEventDelegate:self];

    NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
    onSuccess(successString);
}

- (void)finalizeObject
{
    if (printer == nil) {
        return;
    }

    [printer clearCommandBuffer];
    [printer setReceiveEventDelegate:nil];
     printer = nil;
}

- (int)connectPrinter {
    int result = EPOS2_SUCCESS;
    if (printer == nil) {
        return EPOS2_ERR_PARAM;
    }

    result = [printer connect: self.printerAddress timeout:EPOS2_PARAM_DEFAULT];

    if (result != EPOS2_SUCCESS) {
        [printer clearCommandBuffer];
        return result;
    }
    [printer beginTransaction];
    return result;
}

- (void)disconnectPrinter
{
    int result = EPOS2_SUCCESS;

    if (printer == nil) {
        return;
    }

    result = [printer disconnect];
    int count = 0;
    //Note: Check if the process overlaps with another process in time.
    while(result == EPOS2_ERR_PROCESSING && count < 4) {
        [NSThread sleepForTimeInterval:DISCONNECT_INTERVAL];
        result = [printer disconnect];
        count++;
    }
    if (result != EPOS2_SUCCESS) {
//        [ShowMsg showErrorEpos:result method:@"disconnect"];
    }

    [printer clearCommandBuffer];
    [printer endTransaction];

    NSLog(@"Disconnected!");
}

- (void)printFromBase64: (NSString*)base64String onSuccess: (void(^)(NSString *))onSuccess onError: (void(^)(NSString *))onError
{

        int result = EPOS2_SUCCESS;

        if (self->printer == nil) {
            NSString *errorString = [ErrorManager getEposErrorText: EPOS2_ERR_PARAM];
            onError(errorString);
            return;
        }

        NSData *data = [[NSData alloc] initWithBase64EncodedString: base64String options:0];

        result = [self->printer addCommand:data];
        if (result != EPOS2_SUCCESS) {
            [self->printer clearCommandBuffer];
            NSString *errorString = [ErrorManager getEposErrorText: result];
            onError(errorString);
            return;
        }

        result = [self printData];
        if (result != EPOS2_SUCCESS) {
            NSString *errorString = [ErrorManager getEposErrorText: result];
            onError(errorString);
            return;
        }


        NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
        onSuccess(successString);
}

- (void)getPrinterSettings:(int)type
                           onSuccess: (void(^)(NSString *))onSuccess
                           onError: (void(^)(NSString *))onError {
    int result = [self connectPrinter];

    if (result != EPOS2_SUCCESS) {
        [printer clearCommandBuffer];
        NSString *errorString = [ErrorManager getEposErrorText: result];
        onError(errorString);
        return;
    }

    result = [printer getPrinterSetting:EPOS2_PARAM_DEFAULT type:type delegate:self];

   if (result != EPOS2_SUCCESS) {
        [printer clearCommandBuffer];
        NSString *errorString = [ErrorManager getEposErrorText: result];
        onError(errorString);
        [printer disconnect];
        return;
    }

    NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
    onSuccess(successString);
}

- (void)pairingBluetoothPrinter:(void(^)(NSString *))onSuccess
                               onError: (void(^)(NSString *))onError
{
    Epos2BluetoothConnection *pairingPrinter = [[Epos2BluetoothConnection alloc] init];
    NSMutableString *address = [[NSMutableString alloc] init];
    int result = [pairingPrinter connectDevice: address];

    if(result == EPOS2_BT_SUCCESS || result == EPOS2_BT_ERR_ALREADY_CONNECT) {
        NSString *successString = [ErrorManager getEposBTResultText: EPOS2_BT_SUCCESS];
        onSuccess(successString);
    } else {
        NSString *errorString = [ErrorManager getEposBTResultText: EPOS2_BT_SUCCESS];
        onError(errorString);
    }
}

- (void)onSetPrinterSetting:(int)code {
    // nothing to do
}

- (void)performMonitoring: (NSTimer*)timer {
    int interval = [timer.userInfo intValue];

    __block Epos2PrinterStatusInfo *info;
    __block int result = EPOS2_SUCCESS;

    if(self->isMonitoring_) {
        [self->tasksQueue addOperationWithBlock: ^{
            result = [self connectPrinter];

            if (result != EPOS2_SUCCESS) {
                if(result != EPOS2_ERR_ILLEGAL && result != EPOS2_ERR_PROCESSING) {
                    NSDictionary *msg = [ErrorManager getOfflineStatusMessage];
                    @try {
                      [self sendEventWithName:@"onMonitorStatusUpdate" body: msg];
                    } @catch(NSException *e) {
                    }

                }
            } else {
                info = [self->printer getStatus];

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSDictionary *msg = [ErrorManager makeStatusMessage: info];
                    if(msg != nil){
                      @try {
                        [self sendEventWithName:@"onMonitorStatusUpdate" body: msg];
                      } @catch(NSException *e) {
                      }
                    }
                }];
                [self disconnectPrinter];
            }

               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 [NSTimer scheduledTimerWithTimeInterval: (int)interval target:self selector: @selector(performMonitoring:) userInfo: @(interval) repeats:NO];
               }];

        }];
    }
}

- (void)startMonitorPrinter:(int)interval onSuccess:(void(^)(NSString *))onSuccess
                               onError: (void(^)(NSString *))onError {

    if(isMonitoring_) {
        onError(@"Already monitoring!");
        return;
    }

    if (printer == nil) {
        NSString *errorString = [ErrorManager getEposErrorText: EPOS2_ERR_PARAM];
        onError(errorString);
        return;
    }

    isMonitoring_ = true;

    NSTimer* timer = [NSTimer timerWithTimeInterval: 0.0 target:self selector: @selector(performMonitoring:) userInfo: @(interval) repeats:NO];
    [timer fire];

    NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
    onSuccess(successString);
}

-(void)stopMonitorPrinter:(void(^)(NSString *))onSuccess
                  onError: (void(^)(NSString *))onError
{
    if(!isMonitoring_){
        onError(@"Printer is not monitorring!");
        return;
    }
    [tasksQueue waitUntilAllOperationsAreFinished];
    isMonitoring_= false;

    NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
    onSuccess(successString);
}


- (enum Epos2ErrorStatus)handleCommand: (enum PrintingCommands)command params:(NSArray*)params {
    int result = EPOS2_SUCCESS;
    NSString* text = @"";
    
    switch(command) {
        case COMMAND_ADD_TEXT  :
            text = params[0];
            result = [self->printer addText:text];
          break;
        case COMMAND_ADD_NEW_LINE :
            result = [self->printer addFeedLine:[params[0] intValue]];
          break;
        case COMMAND_ADD_TEXT_STYLE :
            result = [self->printer addTextStyle:EPOS2_FALSE ul:[params[0] intValue] em:[params[1] intValue] color:EPOS2_COLOR_1];
          break;
        case COMMAND_ADD_TEXT_SIZE :
            result = [self->printer addTextSize:[params[0] intValue] height:[params[1] intValue]];
          break;
        case COMMAND_ADD_ALIGN:
            result = [self->printer addTextAlign:[params[0] intValue]];
          break;
        case COMMAND_ADD_IMAGE :
            result = [self->printer addFeedLine:1];
          break;
        case COMMAND_ADD_CUT :
            result = [self->printer addCut:EPOS2_CUT_FEED];
          break;
    }
    
    return result;
}

- (void)printFromBuffer: (NSArray*)buffer onSuccess: (void(^)(NSString *))onSuccess onError: (void(^)(NSString *))onError
{
    int result = EPOS2_SUCCESS;

    if (self->printer == nil) {
        NSString *errorString = [ErrorManager getEposErrorText: EPOS2_ERR_PARAM];
        onError(errorString);
        return;
    }
    
    NSUInteger length = [buffer count];
    for (int j = 0; j < length; j++ ) {
        result = [self handleCommand:[buffer[j][0] intValue] params:buffer[j][1]];
        
        if (result != EPOS2_SUCCESS) {
            [self->printer clearCommandBuffer];
            NSString *errorString = [ErrorManager getEposErrorText: result];
            onError(errorString);
            return;
        }
    }
    
    result = [self printData];
    if (result != EPOS2_SUCCESS) {
        NSString *errorString = [ErrorManager getEposErrorText: result];
        onError(errorString);
        return;
    }

    [self->printer clearCommandBuffer];
    NSString *successString = [ErrorManager getEposErrorText: EPOS2_SUCCESS];
    onSuccess(successString);
}


@end
