import Foundation

/*
 * Data and non UI logic for the companies view
 */
class CompaniesViewModel: ObservableObject {

    private let apiClient: ApiClient

    @Published var companies = [Company]()
    @Published var error: UIError?

    /*
     * Receive global objects whenever the view is recreated
     */
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    /*
     * Do the work of calling the API
     */
    func callApi(options: GetOptions) {

        // Initialise state
        self.error = nil

        Task {

            do {

                // Make the API call on a background thread
                let companies = try await self.apiClient.getCompanies(options: options)
                
                // Update data
                await MainActor.run {
                    self.companies = companies
                }

            } catch {

                await MainActor.run {

                    // Update state and notify
                    self.companies = [Company]()
                    self.error = ErrorFactory.fromException(error: error)
                }
            }
        }
    }
}
