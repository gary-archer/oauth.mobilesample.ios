import Foundation
import SwiftCoroutine

typealias SuccessCallback = () -> Void
typealias ErrorCallback = (UIError) -> Void

/*
* Used when multiple UI fragments attempt an action that needs to be synchronised
*/
class ConcurrentActionHandler {

    private var actionInProgress: Bool
    private var callbacks: [(SuccessCallback, ErrorCallback)]

    /*
     * Initialise the array of promises
     */
    init() {
        self.actionInProgress = false
        self.callbacks = []
    }

    /*
    * Run the supplied action once and return a promise while in progress
    */
    func execute(action: () -> CoFuture<Void>) -> CoFuture<Void> {

        let promise = CoPromise<Void>()

        // Create callbacks through which we'll return the result
        let onSuccess: SuccessCallback = {
            promise.success(Void())
        }
        let onError = { error in
            promise.fail(error)
        }
        self.callbacks.append((onSuccess, onError))

        if !self.actionInProgress {

            self.actionInProgress = true
            do {

                // Do the work
                try action().await()

                // On success resolve all promises
                self.callbacks.forEach { callback in
                    callback.0()
                }

            } catch {

                // On failure resolve all promises with the same error
                let uiError = ErrorHandler().fromException(error: error)
                self.callbacks.forEach { callback in
                    callback.1(uiError)
                }
            }

            // Reset once complete
            self.actionInProgress = false
            self.callbacks = []
        }

        // Return the promise
        return promise
    }

}
