/*
 * An event to move between a loaded state when we have data and an unloaded state otherwise
 */
struct DataStatusEvent {
    let loaded: Bool
}
