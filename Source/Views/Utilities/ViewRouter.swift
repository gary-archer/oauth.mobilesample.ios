import Foundation

/*
* A class to contain data for routing
*/
class ViewRouter: ObservableObject {

    // The current view
    @Published var currentViewType: Any.Type = CompaniesView.Type.self

    // Data passed during navigation
    @Published var params: [Any] = [Any]()

    // This is set to false when a Safari View Controller is active
    var isTopMost: Bool = true
}
