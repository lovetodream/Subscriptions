// 
//  ItemRow.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 22.01.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct ItemRow: View {
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    
    @ObservedObject var item: Item
    
    enum DisplayContext {
        case normal
        case pinned
        case archived
        case budget
    }
    var context: DisplayContext = .normal
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency.currencySymbol
        formatter.internationalCurrencySymbol = currency.currencySymbol
        return formatter
    }
    
    var body: some View {
        Label {
            Text(item.title ?? "Unnamed")
                .lineLimit(1)
            if item.pinned && context == .normal {
                Image(systemName: "pin")
                    .imageScale(.small)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()
            if let cost = item.cost?.decimalValue {
                Text(cost as NSDecimalNumber, formatter: currencyFormatter)
                    .foregroundColor(inCurrentMonth(item, circle: BillingOption(item.billing)) || context == .budget ? .label : .secondaryLabel)
            }
        } icon: {
            if let systemImage = item.systemImage, !systemImage.isEmpty {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
            } else if let data = item.icon, let icon = UIImage(data: data) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .if(roundedIconBorders) {
                        $0.cornerRadius(2)
                    }
            } else {
                Image(systemName: "questionmark")
                    .symbolVariant(.square)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
            }
        }
    }
}

struct ItemRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemRow(item: Item())
    }
}
