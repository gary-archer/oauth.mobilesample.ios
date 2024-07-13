# iOS OAuth Mobile Sample

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1cb3653653ea4a82925fe44dd0d14f7a)](https://app.codacy.com/gh/gary-archer/oauth.mobilesample.ios?utm_source=github.com&utm_medium=referral&utm_content=gary-archer/oauth.mobilesample.ios&utm_campaign=Badge_Grade)

## Overview

* A mobile sample using OpenID Connect and AppAuth
* **The goal is to implement OpenID Connect mobile logins with best usability and reliability**

## Views

The app is a simple UI with some basic navigation between views, to render fictional resources.\
The data is returned from an API that authorizes access to resources using claims from multiple sources.

![App Views](./doc/views.png)

## Local Development Quick Start

Open the app in Xcode, then run the app on a simulator, to trigger an OpenID Connect login flow.\
The AppAuth pattern is used, where logins use an `AsWebAuthenticationSession` system browser.\
This ensures that the app cannot access the user's credentials:

![App Login](./doc/login.png)

You can login to the app using my AWS Cognito test account:

```text
- User: guestuser@example.com
- Password: GuestPassword1
```

An HTTPS redirect URI of `https://mobile.authsamples.com/basicmobileapp/oauth/callback` is used.\
Deep links are then used to receive the login response, in the most secure way.\
A deep linking assets file is registered at https://mobile.authsamples.com/.well-known/apple-app-site-association. \
Interstitial web pages ensure a user gesture after login and logout, so that return to the app is reliable.\
After login you can test all lifecycle operations, including token refresh, expiry events and logout.

## Deep Linking Registration Failures

Some developers may run into the following error after login, where the deep link fails to invoke the mobile app.\
Instead, the URL invoked by [this JavaScript](Web/postlogin.html) runs in the browser, resulting in a `Not Found` error:

![post login error](doc/post-login-error.png)

If you run into this type of problem, the [iOS Code Sample – Infrastructure](https://apisandclients.com/posts/ios-code-sample-infrastructure) blog post explains a couple of ways to resolve the problem.

## Further Information

* See the [API Journey - Client Side](https://apisandclients.com/posts/api-journey-client-side) for further information on the app's behaviour
* Further details specific to the iOS app are provided, starting in the [Code Sample Overview](https://apisandclients.com/posts/ios-code-sample-overview) blog post

## Programming Languages

* Xcode and SwiftUI are used to develop an app that connects to a Cloud API and Authorization Server

## Infrastructure

* [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) is used to implement Authorization Code Flow (PKCE) with a Claimed HTTPS Scheme
* [AWS Serverless](https://github.com/gary-archer/oauth.apisample.serverless) or Kubernetes is used to host remote API endpoints used by the app
* AWS Cognito is used as the default Authorization Server for the Mobile App and API
* The iOS Keychain is used to store encrypted tokens on the device after login
* AWS S3 and Cloudfront are used to serve mobile deep linking asset files and interstitial web pages
