# authguidance.mobilesample.ios

### Overview

* A mobile sample using OAuth 2.0 and Open Id Connect, referenced in my blog at https://authguidance.com
* **The goal of this sample is to implement Open Id Connect mobile logins with best usability and reliability**

### Details

* See the [iOS Code Sample Overview](https://authguidance.com/2020/02/22/ios-code-sample-overview/) for an overview of behaviour
* See the [iOS Code Sample Instructions](https://authguidance.com/2020/02/22/how-to-run-the-ios-code-sample/) for details on how to run the code

### Technologies

* XCode and SwiftUI are used to develop an app that connects to a Cloud API and Authorization Server

### Middleware Used

* The [AppAuth-iOS Library](https://github.com/openid/AppAuth-iOS) implements Authorization Code Flow (PKCE) via a Claimed HTTPS Scheme
* AWS Cognito is used as a Cloud Authorization Server
* The iOS Keychain is used to store encrypted tokens on the device after login
* AWS API Gateway is used to host the back end OAuth 2.0 Secured Web API
* AWS S3 and Cloudfront are used to serve mobile deep linking asset files and interstitial web pages
