import Foundation
import SwiftUI

/*
* A class to manage main view navigation
*/
class ViewRouter: ObservableObject {

    // The current view and its navigation parameters
    @Published var currentViewType: Any.Type = CompaniesView.Type.self
    @Published var params: [Any] = [Any]()

    private let eventBus: EventBus
    var isTopMost: Bool

    init(eventBus: EventBus) {
        self.eventBus = eventBus
        self.isTopMost = true
    }

    /*
     * Called to change the current main view
     */
    func changeMainView(newViewType: Any.Type, newViewParams: [Any]) {

        self.currentViewType = newViewType
        self.params = newViewParams
    }

    /*
     * Deep links include both user navigation events and OAuth redirect responses
     */
    func handleDeepLink(url: URL) {

        // Do not handle deep links when the ASWebAuthenticationSession window is top most
        if self.isTopMost {

            // Handle deep link messages to change location within the app
            let oldViewType = self.currentViewType
            let result = DeepLinkHelper.handleDeepLink(url: url)
            self.changeMainView(newViewType: result.0, newViewParams: result.1)

            // Handle deep linking to transactions for company 2 when transactions for company 4 are active
            // The onAppear function is not called within the transactions view so we need to send an event
            // https://github.com/onmyway133/blog/issues/468
            let isSameView = oldViewType == self.currentViewType
            if isSameView {
                self.eventBus.sendReloadMainViewEvent(causeError: false)
            }
        }
    }

    /*
     * If in the home view the home button behaves differently
     */
    func isInHomeView() -> Bool {
        return self.currentViewType == CompaniesView.Type.self
    }
}
