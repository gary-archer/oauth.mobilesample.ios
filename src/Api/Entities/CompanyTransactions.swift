/*
 * A composite entity of a company and its transactions
 */
struct CompanyTransactions: Decodable {
    let id: Int
    let company: Company
    let transactions: [Transaction]
}
