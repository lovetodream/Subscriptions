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
import StoreKit

struct PremiumIAPView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    
    var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.storeManager.availableProducts.first(where: { $0.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String })?.priceLocale ?? .current
        return formatter
    }
    
    var product: SKProduct? {
        storeManager.availableProducts.first(where: { $0.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String })
    }
    
    var body: some View {
        IAPViewScaffold(success: $lifetimePremium, selectedProduct: .constant(product), title: Text("Unlock all features")) {
            Button {
                if lifetimePremium {
                    dismiss()
                } else if let product = product {
                    storeManager.purchaseProduct(product: product)
                } else {
                    storeManager.getProducts()
                }
            } label: {
                HStack {
                    Spacer()
                    if lifetimePremium {
                        Text("Thank you so much! \(Image(systemName: "heart.fill"))")
                    } else if let transactionState = storeManager.transactionState, transactionState == .purchasing {
                        ProgressView()
                    } else if let product = product {
                        Text("Purchase for \(product.price, formatter: priceFormatter)")
                    } else {
                        Text("Purchase not available, try again...")
                    }
                    Spacer()
                }
                .animation(.default, value: lifetimePremium)
            }
            
            Button {
                withAnimation {
                    storeManager.restoreProducts()
                }
            } label: {
                Text("Restore Purchase")
            }
            .buttonStyle(.borderless)
        } content: {
            VStack(spacing: 20) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Unlimited Subscriptions")
                            .font(.headline)
                        Text("Add as many subscriptions as you want, there is no limit 😁.")
                            .font(.subheadline)
                    }
                    Spacer()
                } icon: {
                    Image(systemName: "infinity")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .symbolVariant(.circle.fill)
                        .foregroundStyle(.green)
                }
                
                // TODO: Future release see [#5](https://github.com/lovetodream/Subscriptions/issues/5)
                if false {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Powerful Suggestions - soon")
                                .font(.headline)
                            Text("Suggestions with options to choose between predefined price plans and more.")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondaryLabel)
                        Spacer()
                    } icon: {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .symbolRenderingMode(.hierarchical)
                            .symbolVariant(.circle.fill)
                            .foregroundColor(Color.purple)
                    }
                }
                
                Label {
                    VStack(alignment: .leading) {
                        Text("Monthly Budget")
                            .font(.headline)
                        Text("Get notified if your monthly subscription cost exceeds your budget.")
                            .font(.subheadline)
                    }
                    Spacer()
                } icon: {
                    Image(systemName: "dollarsign")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .symbolVariant(.square.fill)
                        .foregroundStyle(.orange)
                }
                
                Label {
                    VStack(alignment: .leading) {
                        Text("iCloud Synchronisation")
                            .font(.headline)
                        Text("iCloud Sync will allow your subscriptions to stay in sync across all your devices.")
                            .font(.subheadline)
                    }
                    Spacer()
                } icon: {
                    Image(systemName: "icloud")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .symbolVariant(.square.fill)
                        .foregroundStyle(.blue)
                }
                
                Label {
                    VStack(alignment: .leading) {
                        Text("Support")
                            .font(.headline)
                        Text("Your purchase directly supports the indepentent developer of this app.")
                            .font(.subheadline)
                    }
                    Spacer()
                } icon: {
                    Image(systemName: "heart")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
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
