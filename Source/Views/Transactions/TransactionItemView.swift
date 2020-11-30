import SwiftUI

/*
 * The view for a single transaction
 */
struct TransactionItemView: View {

    @EnvironmentObject private var orientationHandler: OrientationHandler
    private let transaction: Transaction

    init(transaction: Transaction) {
        self.transaction = transaction
    }

    /*
     * Render the transaction values
     */
    var body: some View {

        let deviceWidth = UIScreen.main.bounds.size.width
        return VStack {

            HStack {
                Text("Transaction Id")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(self.transaction.id)
                    .valueStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

            HStack {
                Text("Investor Id")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(self.transaction.investorId)
                    .valueStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()

            HStack {
                Text("Amount USD")
                    .labelStyle()
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

                Text(String(self.transaction.amountUsd))
                    .valueStyle(textColor: Colors.paleGreen)
                    .frame(width: deviceWidth / 3, alignment: .leading)
                    .padding(.leading, deviceWidth / 12)

            }.padding()
        }
    }
}
