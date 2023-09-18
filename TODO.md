1. Store errors in AppViewModel's error object
   Simplify the AppView code
   Get rid of set error event

2. Transactions view to handle a change in the company ID

3. View model coordinator interface updates, based on loading and loaded counts
   Finally keyword missing in Swift so may require some repetition

4. Concurrent hash map for cache
   Concurrent array for token refresh promises

5. Fetch client updates for caching
   View model coordinator updates to read cache results

6. Events renaming and deletion

7. User info tooltip

8. Swift warning improvements to consider
   Make sure I am using latest dependency versions, eg of swiftlint

OTHER UIs
---------
1. Avoid resetting data on every load
   Perhaps I get away with this in React due to a lack of immediate publishing
