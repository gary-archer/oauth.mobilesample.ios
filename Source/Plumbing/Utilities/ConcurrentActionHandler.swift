import Foundation
import SwiftCoroutine

/*
 * Used when multiple UI fragments attempt an action that needs to be synchronised
 * https://basememara.com/creating-thread-safe-arrays-in-swift
*/
class ConcurrentActionHandler {

    // Shorthand notation
    private typealias SuccessCallback = () -> Void
    private typealias ErrorCallback = (UIError) -> Void

    // Properties
    private var callbacks: [(SuccessCallback, ErrorCallback)]
    private let queue: DispatchQueue

    /*
     * Initialise the array of promises
     */
    init() {
        self.callbacks = []
        self.queue = DispatchQueue(label: "ConcurrentArray")
    }

    /*
     * Run the supplied action the first time only and return a promise to the caller
     */
    func execute(action: () -> CoFuture<Void>) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Create callbacks through which we'll return the result for this caller
        let onSuccess: SuccessCallback = {
            promise.success(Void())
        }
        let onError = { error in
            promise.fail(error)
        }

        // Add the callback to the collection, in a thread safe manner
        var performAction = false
        queue.sync {

            self.callbacks.append((onSuccess, onError))
            if self.callbacks.count == 1 {
                performAction = true
            }
        }

        // Perform the action for the first caller only
        if performAction {

            do {

                // Do the work
                try action().await()

                // Resolve all promises with the same success result
                queue.sync {
                    self.callbacks.forEach { callback in
                        callback.0()
                    }
                }

            } catch {

                // Resolve all promises with the same error
                let uiError = ErrorHandler.fromException(error: error)
                queue.sync {
                    self.callbacks.forEach { callback in
                        callback.1(uiError)
                    }
                }
            }

            // Reset once complete
            queue.sync {
                self.callbacks = []
            }
        }

        // Return the promise
        return promise
    }

}
