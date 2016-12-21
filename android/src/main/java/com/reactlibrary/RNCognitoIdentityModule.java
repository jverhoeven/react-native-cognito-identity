
package com.reactlibrary;

import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserSession;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.AuthenticationContinuation;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.AuthenticationDetails;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.ForgotPasswordContinuation;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.continuations.MultiFactorAuthenticationContinuation;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.AuthenticationHandler;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.ForgotPasswordHandler;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.GenericHandler;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;

import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.AnonymousAWSCredentials;
import com.amazonaws.regions.Region;
import com.amazonaws.regions.Regions;


import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserPool;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserAttributes;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.handlers.SignUpHandler;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUser;
import com.amazonaws.mobileconnectors.cognitoidentityprovider.CognitoUserCodeDeliveryDetails;
import com.amazonaws.services.cognitoidentityprovider.AmazonCognitoIdentityProviderClient;
import com.facebook.react.bridge.WritableMap;

import java.util.HashMap;
import java.util.Map;


public class RNCognitoIdentityModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private final AmazonCognitoIdentityProviderClient client;
    private CognitoUserPool userPool;
    private ForgotPasswordContinuation forgotPasswordContinuation;

    public RNCognitoIdentityModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.client = new AmazonCognitoIdentityProviderClient(new AnonymousAWSCredentials(), new ClientConfiguration());
        this.userPool = null;
        this.forgotPasswordContinuation = null;
    }

    @Override
    public String getName() {
        return "RNCognitoIdentity";
    }

    @ReactMethod
    public void concatStr(
            String string1,
            String string2,
            Promise promise) {
        promise.resolve(string1 + " " + string2);
    }

    @ReactMethod
    public void signUp(
            String email,
            String password,
            final Promise promise) {

        CognitoUserAttributes userAttributes = new CognitoUserAttributes();
        userAttributes.addAttribute("email", email);
        SignUpHandler signupCallback = new SignUpHandler() {
            @Override
            public void onSuccess(CognitoUser cognitoUser, boolean userConfirmed, CognitoUserCodeDeliveryDetails cognitoUserCodeDeliveryDetails) {
                promise.resolve(cognitoUser.getUserId());
            }

            @Override
            public void onFailure(Exception exception) {
                promise.reject(exception);
            }
        };
        userPool.signUpInBackground(email, password, userAttributes, null, signupCallback);
    }

    @ReactMethod
    public void confirmSignUp(
            final String email,
            String confirmationCode,
            final Promise promise) {

        CognitoUser user = this.userPool.getUser(email);
        GenericHandler confirmSignupCallback = new GenericHandler() {
            @Override
            public void onSuccess() {
                promise.resolve(email);
            }

            @Override
            public void onFailure(Exception exception) {
                promise.reject(exception);
            }
        };
        user.confirmSignUp(confirmationCode, false, confirmSignupCallback);
    }

    @ReactMethod
    public void getSession(
            final String email,
            final String password,
            final Promise promise) {

        CognitoUser user = this.userPool.getUser(email);
        AuthenticationHandler authenticationCallback = new AuthenticationHandler() {

            @Override
            public void getAuthenticationDetails(AuthenticationContinuation authenticationContinuation, String UserId) {
                AuthenticationDetails authDetails = new AuthenticationDetails(email, password, null);

                // Now allow the authentication to continue
                authenticationContinuation.setAuthenticationDetails(authDetails);
                authenticationContinuation.continueTask();
            }

            @Override
            public void getMFACode(MultiFactorAuthenticationContinuation continuation) {
                continuation.continueTask();
            }

            @Override
            public void onSuccess(CognitoUserSession userSession) {
                // Sign-up was successful
                WritableMap session = Arguments.createMap();
                session.putString("idToken", userSession.getIdToken().getJWTToken());
                session.putString("accessToken", userSession.getAccessToken().getJWTToken());
                session.putString("refreshToken", userSession.getRefreshToken().getToken());
                promise.resolve(session);
            }

            @Override
            public void onFailure(Exception exception) {
                // Sign-up failed, check exception for the cause
                promise.reject("signup failed", exception);
            }
        };
        user.getSessionInBackground(authenticationCallback);
    }

    @ReactMethod
    public void forgotPassword(
            final String email,
            final Promise promise) {

        CognitoUser user = this.userPool.getUser(email);
        ForgotPasswordHandler forgotPasswordCallback = new ForgotPasswordHandler() {
            @Override
            public void onSuccess() {
                promise.resolve(email);
            }

            @Override
            public void getResetCode(ForgotPasswordContinuation continuation) {
                promise.resolve(email);
            }

            @Override
            public void onFailure(Exception exception) {
                promise.reject(exception);
            }
        };
        user.forgotPasswordInBackground(forgotPasswordCallback);
    }


    @ReactMethod
    public void confirmForgotPassword(
            final String email,
            final String newPassword,
            final String confirmationCode,
            final Promise promise) {

        CognitoUser user = this.userPool.getUser(email);
        ForgotPasswordHandler confirmForgotPasswordHandler = new ForgotPasswordHandler() {
            @Override
            public void onSuccess() {
                promise.resolve(email);
            }

            @Override
            public void getResetCode(ForgotPasswordContinuation continuation) {
                continuation.continueTask();
            }

            @Override
            public void onFailure(Exception exception) {
                promise.reject(exception);
            }
        };
        user.confirmPasswordInBackground(confirmationCode, newPassword, confirmForgotPasswordHandler);
    }

    @ReactMethod
    public void logout(final String email) {
        CognitoUser user = this.userPool.getUser(email);
        user.signOut();
    }

    @ReactMethod
    public void initWithOptions(
            String region,
            String userPoolId,
            String clientId) {
        // Sorry, hard coded as well.
        this.client.setRegion(Region.getRegion(Regions.EU_WEST_1));
        this.userPool = new CognitoUserPool(this.reactContext, userPoolId, clientId, null, this.client);
    }

}