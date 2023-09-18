TIDY UP
-------
1. Store errors in AppViewModel's error object
   Remove catching from the AppView class
   Get rid of set error event

2. Transactions view to handle a change in the company ID

3. View model coordinator interface updates, based on loading and loaded counts
   Finally keyword missing in Swift so may require some repetition
   Merge code

REFINEMENTS
-----------
1. User info tooltip

2. Swift warning improvements to consider
   Make sure I am using latest dependency versions, eg of swiftlint

FETCH CACHE
-----------
1. Concurrent hash map
   Concurrent array for token refresh promises

2. Fetch client updates
   View model coordinator updates to read cache results

3. Events renaming and deletion

4. Final AppView and AppViewModel consolidation

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
