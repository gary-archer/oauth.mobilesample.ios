FETCH CACHE
-----------
1. Create child branch

2. View models to use viewmodelcoordinator interface
   Delete ApiViewEvents and ApiViewLoadState
   Consider where global objects are created and whether this should be in the app view model?

3. FetchRequestOptions to complete
   Fetch client updates to API requests
   Detailed testing and tracing, then check in and merge to viewmodel branch

REFINEMENTS
-----------
1. Final AppView and AppViewModel consolidation
   ReloadMain / ReloadUserInfo Events to improve

2. User info tooltip

3. Swift warning improvements
   Make sure I am using latest dependency versions, eg of swiftlint
   Then merge to master

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
   Also review usage of companyId in transactions view model, for consistency
