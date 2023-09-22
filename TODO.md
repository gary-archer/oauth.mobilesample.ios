FETCH CACHE
-----------
1. Debug to get back to a basic working state

2. Fetch client updates to API requests
   Detailed testing and tracing, then check in
   Merge to viewmodel branch

FINALIZATION
-----------
1. Final AppView and AppViewModel consolidation
   ReloadMain / ReloadUserInfo Events to improve
   Review navigated event

2. Other final UIs to behave equivalently
   Navigated event needs looking at
   Avoid resetting existing data in view models, except if transaction ID changes or there is an error
   Use onForbidden consistently perhaps
   Does React always need to call setState manually - or is there a neater way?
   Inspect use of event bus for responsibilities that should be in the model
   Avoid storing companyID in transactions view when redundant
   Reload user info on error should be equivalent to others
   
REFINEMENTS
-----------
1. User info tooltip

2. Swift warning improvements
   Make sure I am using latest dependency versions, eg of swiftlint
   Then merge to master

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
   Also review usage of companyId in transactions view model, for consistency
