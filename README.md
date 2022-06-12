# iOS OAuth Mobile Sample

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/f7629f3989ab40a199043f1d84dd8fb5)](https://www.codacy.com/gh/gary-archer/oauth.mobilesample.ios/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=gary-archer/oauth.mobilesample.ios&amp;utm_campaign=Badge_Grade)

## Overview

* A mobile sample using OpenID Connect and AppAuth, referenced in my blog at https://authguidance.com
* **The goal is to implement OpenID Connect mobile logins with best usability and reliability**

## Further Information

* See the [iOS Code Sample Overview](https://authguidance.com/2020/02/22/ios-code-sample-overview/) for an overview of behaviour
* See the [iOS Code Sample Instructions](https://authguidance.com/2020/02/22/how-to-run-the-ios-code-sample/) for details on how to run the code

## Programming Languages

* Xcode and SwiftUI are used to develop an app that connects to a Cloud API and Authorization Server

## Infrastructure

* [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) is used to implement Authorization Code Flow (PKCE) with a Claimed HTTPS Scheme
* AWS API Gateway is used to host the back end OAuth Secured Web API
* AWS Cognito is used as the default Authorization Server for the Mobile App and API
* The iOS Keychain is used to store encrypted tokens on the device after login
* AWS S3 and Cloudfront are used to serve mobile deep linking asset files and interstitial web pages
