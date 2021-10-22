/*
 * An event sent to force the view to trigger a request for new data from the API
 */
struct ReloadEvent {
    let viewName: String
    let causeError: Bool
}
