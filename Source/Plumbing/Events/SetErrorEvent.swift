/*
 * An event to set or clear details in an instance of the error summary view
 */
struct SetErrorEvent {
    let containingViewName: String
    let error: UIError?
}
