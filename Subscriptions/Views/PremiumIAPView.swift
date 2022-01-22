//
//  PremiumIAPView.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 09.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import StoreKit.SKProduct

struct PremiumIAPView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    
    var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.storeManager.availableProducts.first(where: {
            $0.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String
        })?.priceLocale ?? .current
        return formatter
    }
    
    var product: SKProduct? {
        storeManager.availableProducts.first(where: {
            $0.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String
        })
    }
    
    var body: some View {
        IAPViewScaffold(success: $lifetimePremium, selectedProduct: .constant(product), title: Text("Unlock all features")) {
            PurchaseButton(success: $lifetimePremium, product: .constant(product)) {
                if let product = product {
                    Text("Purchase for \(product.price, formatter: priceFormatter)")
                } else {
                    Text("Purchase not available, try again...")
                }
            }
            .animation(.default, value: lifetimePremium)
            .environmentObject(storeManager)
                        
            RestoreButton()
                .environmentObject(storeManager)
        } content: {
            VStack(spacing: 20) {
                IAPBenefit(headline: Text("Unlimited Subscriptions"),
                           subheadline: Text("Add as many subscriptions as you want, there is no limit 😁.")) {
                    Image(systemName: "infinity")
                        .symbolVariant(.circle.fill)
                        .foregroundStyle(.green)
                }
                
                // TODO: Future release see [#5](https://github.com/lovetodream/Subscriptions/issues/5)
                if false {
                    IAPBenefit(previewFeature: true,
                               headline: Text("Powerful Suggestions - soon"),
                               subheadline: Text("Suggestions with options to choose between predefined price plans and more.")) {
                        Image(systemName: "magnifyingglass")
                            .symbolVariant(.circle.fill)
                            .foregroundColor(Color.purple)
                    }
                }
                
                IAPBenefit(headline: Text("Monthly Budget"),
                           subheadline: Text("Get notified if your monthly subscription cost exceeds your budget.")) {
                    Image(systemName: "dollarsign")
                        .symbolVariant(.square.fill)
                        .foregroundStyle(.orange)
                }
                
                IAPBenefit(headline: Text("iCloud Synchronisation"),
                           subheadline: Text("iCloud Sync will allow your subscriptions to stay in sync across all your devices.")) {
                    Image(systemName: "icloud")
                        .symbolVariant(.square.fill)
                        .foregroundStyle(.blue)
                }
                
                IAPBenefit(headline: Text("Support"),
                           subheadline: Text("Your purchase directly supports the independent developer of this app.")) {
                    Image(systemName: "heart")
                        .symbolVariant(.square.fill)
                        .foregroundStyle(.red)
                }
                
                Text("And many more to come with future updates")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
            }
            .padding(.horizontal, 25)
            .padding(.vertical)
        }
    }
}

struct PremiumIAPView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumIAPView()
            .environmentObject(StoreManager())
    }
}
