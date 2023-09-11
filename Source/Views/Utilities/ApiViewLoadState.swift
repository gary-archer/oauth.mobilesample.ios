/*
 * Information about each view
 */
class ApiViewLoadState {

    let name: String
    var loaded: Bool
    var failed: Bool

    init(name: String, loaded: Bool, failed: Bool) {
        self.name = name
        self.loaded = loaded
        self.failed = failed
    }
}
