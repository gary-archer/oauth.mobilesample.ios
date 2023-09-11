import Foundation

/*
 * Used when multiple UI fragments attempt an action that needs to be synchronised
 * https://basememara.com/creating-thread-safe-arrays-in-swift
*/
class ConcurrentActionHandler {

    private var continuations: [CheckedContinuation<(), Error>]
    private let queue: DispatchQueue

    /*
     * Initialise the array of promises
     */
    init() {
        self.queue = DispatchQueue(label: "ConcurrentArray")
        self.continuations = []
    }

    /*
     * Run the supplied action the first time only and return a promise to the caller
     */
    func execute(action: @escaping () async throws -> Void) async throws {

        return try await withCheckedThrowingContinuation { continuation in

            // Add the callback to the collection, in a thread safe manner
            queue.sync {
                self.continuations.append(continuation)
            }

            // Perform the action for the first caller only
            if self.continuations.count == 1 {

                Task {
                    do {
                        // Do the work
                        try await action()

                        // Resolve all promises with the same success result
                        queue.sync {
                            self.continuations.forEach { continuation in
                                continuation.resume()
                            }
                        }

                    } catch {

                        // Resolve all promises with the same error
                        let uiError = ErrorFactory.fromException(error: error)
                        queue.sync {
                            self.continuations.forEach { continuation in
                                continuation.resume(throwing: uiError)
                            }
                        }
                    }

                    // Reset once complete
                    queue.sync {
                        self.continuations = []
                    }
                }
            }
        }
    }
}
