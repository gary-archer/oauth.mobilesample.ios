FETCH CACHE
-----------
1. Concurrent hash map
   Concurrent array for token refresh promises

2. Fetch client updates
   View model coordinator updates to read cache results

3. View model coordinator interface updates, based on loading and loaded counts
   Finally keyword missing in Swift so may require some repetition
   Merge code

4. Events renaming and deletion

5. Final AppView and AppViewModel consolidation

REFINEMENTS
-----------
1. User info tooltip

2. Swift warning improvements to consider
   Make sure I am using latest dependency versions, eg of swiftlint

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
   Also review usage of companyId in transactions view model, for consistency
