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
* AWS API Gateway is used to host our sample OAuth 2.0 Secured API
