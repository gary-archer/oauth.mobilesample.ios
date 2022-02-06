import SwiftUI

/*
 * The view for a single company item
 */
struct CompanyItemView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    @ObservedObject private var viewRouter: ViewRouter
    private let company: Company

    init (viewRouter: ViewRouter, company: Company) {
        self.viewRouter = viewRouter
        self.company = company
    }

    /*
     * Render the company UI elements
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            HStack {
                Text(self.company.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(self.company.region)
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

            HStack {
                Text("Target USD")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(self.formatAmount(value: self.company.targetUsd))
                    .valueStyle(textColor: Colors.paleGreen)
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

            HStack {
                Text("Investment USD")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(self.formatAmount(value: self.company.investmentUsd))
                    .valueStyle(textColor: Colors.paleGreen)
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

            HStack {
                Text("# Investors")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(String(self.company.noInvestors))
                    .valueStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

        }.contentShape(Rectangle())
         .onTapGesture {
            self.moveToTransactions(id: self.company.id)
        }
    }

    /*
     * Format an amount field to include thousands separators
     */
    private func formatAmount(value: Int) -> String {
        return String(format: "%.0f", locale: Locale.current, Double(value))
    }

    /*
     * When a company is clicked, move to the transactions view and indicate which item
     */
    private func moveToTransactions(id: Int) {

        self.viewRouter.changeMainView(
            newViewType: TransactionsView.Type.self,
            newViewParams: [String(id)])
    }
}
