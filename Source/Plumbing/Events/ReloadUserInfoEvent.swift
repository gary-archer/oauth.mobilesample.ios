/*
 * An event sent to force the view to get new data from the API
 */
struct ReloadUserInfoEvent {
    let causeError: Bool
}
