# react-native-cognito-identity

## Purpose

This library is a stop gap until Amazon releases a full React-Native SDK. 

This library focuses on management of Cognito identities: Signup, Get session tokens, Forgot password workflows etc. I also created a React Native demo application that uses this library: https://github.com/jverhoeven/ReactNativeCognitoDemo.

My needs:

1. Allow new users to sign up, verify e-mail address.
2. Allow users to go through 'forgot password' scenario when needed.
3. Get a session token as JWT token which can be used to access web APIs.

Limitations:

1. You need to store the password on the client. Currently the refresh token is not used to get new session tokens.
2. It assumes the e-mail address is the username.
3. Not all functionality is implemented, e.g. you cannot change the e-mail address after signup.
4. No tests.
5. Android only does region EU-WEST-1

## Getting started

`$ npm install react-native-cognito-identity --save`

Followed by:

`$ react-native link react-native-cognito-identity`

For iOS you need to do following as well:

1. Download the AWS iOS SDK: https://aws.amazon.com/mobile/sdk/
2. Unpack it, from the /Frameworks folder take 

		AWSCognito.framework
		AWSCognitoIdentityProvider.framework
		AWSCore.framework
	
	and copy them into the node_modules/react-native-cognito-identity/ios/Frameworks/ folder.
	
The AWS framework packages are not included to avoid the need to update them.

## Usage
```javascript
import RNCognitoIdentity from 'react-native-cognito-identity';

// Example, sign up with a new email (i.e. username) and password:
const signupResponse = await RNCognitoIdentity.signUp(email, password);

// Then get the verification code sent via e-mail via the GUI and call:
result = await RNCognitoIdentity.confirmSignUp(email, verificationCode);

// Then you should be able to login:
var session = await RNCognitoIdentity.getSession(email, password);

// When successful, the session object should contain JWT tokens:
console.log("The idToken: " + session["idToken"]);
console.log("The accessToken: " + session["accessToken"]);
console.log("The refreshToken: " + session["refreshToken"]);
console.log("The expirationTime: " + session["expirationTime"]); //iOS only
```
For a full example go to https://github.com/jverhoeven/ReactNativeCognitoDemo.
## Todo
This is a minimal implementation that satisfies my own applications. Obviously you will want to:

1. Implement the full interface
2. (Automatically) refresh the session tokens using the refreshToken, so you don't have to store the password.
3. Write tests.

