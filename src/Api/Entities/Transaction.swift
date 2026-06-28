/*
 * A transaction entity returned from the API
 */
struct Transaction: Decodable {
    let id: String
    let investorId: String
    let amountUsd: Int
}
