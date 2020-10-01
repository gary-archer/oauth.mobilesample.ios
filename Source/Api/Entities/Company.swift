/*
 * A company entity received from the API
 */
struct Company: Decodable {
    let id: Int
    let name: String
    let region: String
    let targetUsd: Int
    let investmentUsd: Int
    let noInvestors: Int
}
