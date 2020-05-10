# authguidance.mobilesample.ios

### Overview

* A mobile sample using OAuth 2.0 and Open Id Connect, referenced in my blog at https://authguidance.com
* **The goal of this sample is to implement Open Id Connect mobile logins with best usability and reliability**

### Details

* See the iOS Code Sample Overview for an overview of behaviour
* See the iOS Code Sample Instructions for details on how to run the code

### Technologies

* Swift and SwiftUI are used to develop an app that connects to a Cloud API and Authorization Server
* Navigation scenarios related to logins and deep links are handled via https://authguidance-examples.com

### Middleware Used

* The [AppAuth-iOS Library](https://github.com/openid/AppAuth-iOS) is used to implement the Authorization Code Flow (PKCE)
* AWS Cognito is used as a Cloud Authorization Server
* The iOS Keychain is used to store encrypted tokens on the device after login
* AWS API Gateway is used to host the back end OAuth 2.0 Secured Web API
* AWS Cloudfront is used to host mobile deep linking asset files
