
#import "RNCognitoIdentity.h"
#import "AWSRNHelper.h"

@implementation RNCognitoIdentity {
    AWSRNHelper *helper;
    NSDateFormatter *_dateFormatterISO8601;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(RNCognitoIdentity);

-(instancetype)init{
    self = [super init];
    if (self) {
        [AWSServiceConfiguration
         addGlobalUserAgentProductToken:[NSString stringWithFormat:@"react-native-kickass-component/0.0.1"]];
        helper = [[AWSRNHelper alloc] init];
    }
    return self;
}

-(NSDateFormatter*) dateFormatterISO8601 {
    if(! _dateFormatterISO8601){
        _dateFormatterISO8601 = [[NSDateFormatter alloc] init];
        [_dateFormatterISO8601 setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatterISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    }
    return _dateFormatterISO8601;
}

RCT_EXPORT_METHOD(signUp:(NSString *)email
                  password:(NSString *)password
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {

    // get user pool as defined in initWithOptions:
    AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
    
    // Now signup:
    AWSCognitoIdentityUserAttributeType * emailAttribute = [AWSCognitoIdentityUserAttributeType new];
    emailAttribute.name = @"email";
    emailAttribute.value = email;
    
    //start a separate thread for this to avoid blocking the component queue, since
    //it will have to comunicate with the javascript in the mean time while trying to signup
    NSString* queueName = [NSString stringWithFormat:@"%@.signUpQueue",
                           [NSString stringWithUTF8String:dispatch_queue_get_label(self.methodQueue)]
                           ];
    dispatch_queue_t concurrentQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        
        [[userPool signUp:email password:password userAttributes:@[emailAttribute] validationData:nil]
         continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserPoolSignUpResponse *> * _Nonnull task) {
             
             if (task.exception){
                 reject([NSString stringWithFormat:@"Exception "],task.exception.reason, [[NSError alloc] init]);
             }
             if (task.error) {
                 reject([NSString stringWithFormat:@"%ld",task.error.code],task.error.description,task.error);
             }
             else {
                 // Return the username as registered with Cognito.
                 resolve(task.result.user.username);
             }
             return nil;
         }];
        
    });
}

// - (AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse *> *)confirmSignUp:(NSString *)confirmationCode;

RCT_EXPORT_METHOD(confirmSignUp:(NSString *)newEmail confirmationCode:(NSString *)confirmationCode resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString* queueName = [NSString stringWithFormat:@"%@.confirmSignUpQueue",
                           [NSString stringWithUTF8String:dispatch_queue_get_label(self.methodQueue)]
                           ];
    dispatch_queue_t concurrentQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        
        AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
        AWSCognitoIdentityUser *user = [userPool getUser:newEmail];
        
        [[user confirmSignUp:confirmationCode] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse *> * _Nonnull task) {
            if (task.exception){
                dispatch_async(dispatch_get_main_queue(), ^{
                    @throw [NSException exceptionWithName:task.exception.name reason:task.exception.reason userInfo:task.exception.userInfo];
                });
            }
            if (task.error) {
                reject([NSString stringWithFormat:@"%ld",task.error.code],task.error.description,task.error);
            }
            else {
                resolve(newEmail);
            }
            return nil;
            
        }];
    });
}

RCT_EXPORT_METHOD(getSession:(NSString *)newEmail password:(NSString *)newPassword resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    //start a separate thread for this to avoid blocking the component queue, since
    //it will have to comunicate with the javascript in the mean time while trying to get the list of logins
    NSString* queueName = [NSString stringWithFormat:@"%@.getSessionQueue",
                           [NSString stringWithUTF8String:dispatch_queue_get_label(self.methodQueue)]
                           ];
    dispatch_queue_t concurrentQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        
        AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
        AWSCognitoIdentityUser *user = [userPool getUser:newEmail];
        
        [[user getSession:newEmail password:newPassword validationData:nil] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityProviderRespondToAuthChallengeResponse *> * _Nonnull task) {
            if (task.exception){
                dispatch_async(dispatch_get_main_queue(), ^{
                    @throw [NSException exceptionWithName:task.exception.name reason:task.exception.reason userInfo:task.exception.userInfo];
                });
            }
            if (task.error) {
                reject([NSString stringWithFormat:@"%ld",task.error.code],task.error.description,task.error);
            }
            else {
                AWSCognitoIdentityUserSession *session = (AWSCognitoIdentityUserSession *)task.result;
                NSString* dateAsISO8601String = [[self dateFormatterISO8601] stringFromDate:session.expirationTime];
                
                NSDictionary *dict = @{
                                       @"idToken":session.idToken.tokenString,
                                       @"accessToken":session.accessToken.tokenString,
                                       @"refreshToken":session.refreshToken.tokenString,
                                       @"expirationTime":dateAsISO8601String};
                resolve(dict);
            }
            return nil;
        }];
        
    });
}

RCT_EXPORT_METHOD(forgotPassword:(NSString *)newEmail resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString* queueName = [NSString stringWithFormat:@"%@.forgotPasswordQueue",
                           [NSString stringWithUTF8String:dispatch_queue_get_label(self.methodQueue)]
                           ];
    dispatch_queue_t concurrentQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        
        AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
        AWSCognitoIdentityUser *user = [userPool getUser:newEmail];
        
        [[user forgotPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserForgotPasswordResponse *> * _Nonnull task) {
            if (task.exception){
                dispatch_async(dispatch_get_main_queue(), ^{
                    @throw [NSException exceptionWithName:task.exception.name reason:task.exception.reason userInfo:task.exception.userInfo];
                });
            }
            if (task.error) {
                reject([NSString stringWithFormat:@"%ld",task.error.code],task.error.description,task.error);
            }
            else {
                //AWSCognitoIdentityProviderCodeDeliveryDetailsType *codeDeliveryDetails = (AWSCognitoIdentityProviderCodeDeliveryDetailsType *)task.result.codeDeliveryDetails;
                resolve(newEmail);
            }
            return nil;
            
        }];
    });
}

// - (AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> *)confirmForgotPassword:(NSString *)confirmationCode
// password:(NSString *)password;
RCT_EXPORT_METHOD(confirmForgotPassword:(NSString *)newEmail password:(NSString *)newPassword confirmationCode:(NSString *)confirmationCode resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString* queueName = [NSString stringWithFormat:@"%@.confirmForgotPasswordAsyncQueue",
                           [NSString stringWithUTF8String:dispatch_queue_get_label(self.methodQueue)]
                           ];
    dispatch_queue_t concurrentQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        
        AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
        AWSCognitoIdentityUser *user = [userPool getUser:newEmail];
        
        [[user confirmForgotPassword:confirmationCode password:newPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> * _Nonnull task) {
            if (task.exception){
                dispatch_async(dispatch_get_main_queue(), ^{
                    @throw [NSException exceptionWithName:task.exception.name reason:task.exception.reason userInfo:task.exception.userInfo];
                });
            }
            if (task.error) {
                reject([NSString stringWithFormat:@"%ld",task.error.code],task.error.description,task.error);
            }
            else {
                resolve(newEmail);
            }
            return nil;
            
        }];
    });
}



RCT_EXPORT_METHOD(logout:(NSString *)email) {
    AWSCognitoIdentityUserPool *userPool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];
    AWSCognitoIdentityUser *user = [userPool getUser:email];
    if (user) [user signOut];
}


RCT_EXPORT_METHOD(initWithOptions:(NSString *)region
                       userPoolId:(NSString *)userPoolId
                         clientId:(NSString *)clientId)
{
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:[helper regionTypeFromString:region] credentialsProvider:nil];
    [configuration addUserAgentProductToken:@"AWSCognitoCredentials"];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    AWSCognitoIdentityUserPoolConfiguration *userPoolConfiguration = [[AWSCognitoIdentityUserPoolConfiguration alloc] initWithClientId:clientId
                                                                                                                          clientSecret:nil
                                                                                                                                poolId:userPoolId];
    [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:configuration userPoolConfiguration:userPoolConfiguration forKey:@"UserPool"];
}



@end
  
