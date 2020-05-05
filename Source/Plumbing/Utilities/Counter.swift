import Foundation

/*
 * A counter utility
 */
class Counter {

    private static var value = 0

    static func getAndIncrement() -> Int {
        value += 1
        return value
    }
}
