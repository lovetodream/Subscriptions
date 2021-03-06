//
//  TipJarView.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 16.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import StoreKit.SKProduct

struct TipJarView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: SKProduct?
    @State private var success = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tip.timestamp, ascending: true)], animation: .default)
    private var previousPurchases: FetchedResults<Tip>
    
    private var availableProducts: [SKProduct] {
        storeManager.availableProducts.filter {
            $0.productIdentifier != Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String
        }.sorted {
            $0.price.decimalValue < $1.price.decimalValue
        }
    }
    
    private var fullPurchaseAmount: (Decimal, String) {
        // Purchases in different currencies are ignored, the locale of the last purchase will be used
        var price: Decimal = 0
        previousPurchases.forEach { tip in
            price += tip.price?.decimalValue ?? 0
        }
        return (price, previousPurchases.last?.currency ?? Locale.current.currencyCode ?? "USD")
    }
    
    var body: some View {
        IAPViewScaffold(success: $success,
                        selectedProduct: $selectedProduct,
                        title: Text("Tip Jar")) {
            PurchaseButton(success: $success,
                           product: $selectedProduct) {
                Text(selectedProduct!.localizedTitle) + Text(" ") +
                Text(selectedProduct!.price.decimalValue,
                     format: .currency(code: getCurrencyCode(for: selectedProduct!)))
            }
            .environmentObject(storeManager)
        } content: {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 500))]) {
                ForEach(availableProducts, id: \.productIdentifier) { product in
                    Button {
                        withAnimation {
                            selectedProduct = product
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(product.price.decimalValue,
                                 format: .currency(code: getCurrencyCode(for: product)))
                            Spacer()
                        }
                    }
                    .if(selectedProduct == product) {
                        $0.buttonStyle(.borderedProminent)
                    }
                    .if(selectedProduct != product) {
                        $0.buttonStyle(.bordered)
                    }
                    .controlSize(.large)
                }
                .onAppear {
                    selectedProduct = availableProducts.first
                }
            }
            
            VStack {
                Text("You have tipped a total of \(fullPurchaseAmount.0, format: .currency(code: fullPurchaseAmount.1))")
                    .multilineTextAlignment(.center)
            }
            
            VStack {
                Text("Why a Tip Jar?")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                
                Text("""
The tip jar helps keep Abonementi running, and helps with getting regular (and substantial) updates pushed out to you.

If you enjoy using this app and want to support an independent app developer (that's me, Timo), please consider leaving a tip, an App Store rating/review, or telling a friend about how much you like Abonementi.

Thank you for being awesome!
""")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 30)
        }
        .environmentObject(storeManager)
    }
}

struct TipJarView_Previews: PreviewProvider {
    static var previews: some View {
        TipJarView()
            .environmentObject(StoreManager())
    }
}
