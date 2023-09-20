1. UserInfoViewModel to fetch client

FETCH CACHE
-----------
1. Create child branch
   Updates to view models to use viewmodelcoordinator interface and publish results
   Use publish technique from ApiViewEvents, then delete it and ApiViewLoadState
   
2. FetchRequestOptions to complete
   Fetch client updates to API requests
   Detailed testing and tracing, then check in and merge to viewmodel branch

REFINEMENTS
-----------
1. Final AppView and AppViewModel consolidation
   Events renaming and deletion

2. User info tooltip

3. Swift warning improvements
   Make sure I am using latest dependency versions, eg of swiftlint
   Then merge to master

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
   Also review usage of companyId in transactions view model, for consistency
