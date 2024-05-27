import Foundation
import SwiftUI

/*
* A class to manage main view navigation
*/
class ViewRouter: ObservableObject {

    // Values published to views
    @Published var activeViewType: Any.Type = BlankView.Type.self
    @Published var activeViewParams: [Any] = [Any]()

    // Internal values
    private var lastViewType: Any.Type = CompaniesView.Type.self
    private var lastViewParams: [Any] = [Any]()
    private var isStartupDeepLink = false
    private let eventBus: EventBus
    var isTopMost: Bool

    init(eventBus: EventBus) {
        self.eventBus = eventBus
        self.isTopMost = true
    }

    /*
     * Indcate whether the app is being started by a deep link
     */
    func setStartupDeepLink() {
        isStartupDeepLink = true
    }

    /*
     * On expiry, move to the login required view while maintaining the last view path to return to after login
     */
    func navigateToLoginRequired() {

        self.lastViewType = self.activeViewType
        self.lastViewParams = self.activeViewParams
        self.changeMainView(newViewType: LoginRequiredView.Type.self, newViewParams: [])
    }

    /*
     * After an explicit logout, reset the last view and move to the login required view
     */
    func navigateToLoggedOut() {

        self.lastViewType = CompaniesView.Type.self
        self.lastViewParams = []
        self.navigateToLoginRequired()
    }

    /*
     * Navigate to an application path
     */
    func navigateToPath(newViewType: Any.Type, newViewParams: [Any]) {

        self.lastViewType = newViewType
        self.lastViewParams = newViewParams
        self.changeMainView(newViewType: newViewType, newViewParams: newViewParams)
    }

    /*
     * Navigation back to the last view after login
     */
    func navigateAfterLogin() {
        self.changeMainView(newViewType: self.lastViewType, newViewParams: self.lastViewParams)
    }

    /*
     * Deep links include both user navigation events and OAuth redirect responses
     */
    func handleDeepLink(url: URL) {

        // Do not handle deep links when the ASWebAuthenticationSession window is top most
        if self.isTopMost {

            // Handle deep link messages to change location within the app
            let oldViewType = self.activeViewType
            let result = DeepLinkHelper.handleDeepLink(url: url)
            self.navigateToPath(newViewType: result.0, newViewParams: result.1)

            // Handle deep linking to transactions for company 2 when transactions for company 4 are active
            // The onAppear function is not called within the transactions view so we need to send an event
            // https://github.com/onmyway133/blog/issues/468
            let isSameView = oldViewType == self.activeViewType
            if isSameView {
                self.eventBus.sendReloadDataEvent(causeError: false)
            }
        }
    }

    /*
     * Change the active main view
     */
    private func changeMainView(newViewType: Any.Type, newViewParams: [Any]) {

        self.activeViewType = newViewType
        self.activeViewParams = newViewParams
    }
}
