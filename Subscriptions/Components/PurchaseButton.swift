// 
//  PurchaseButton.swift
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
import StoreKit.SKProduct

struct PurchaseButton<ProductLabel: View>: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var storeManager: StoreManager
    
    @Binding var success: Bool
    @Binding var product: SKProduct?
    
    var productLabel: () -> ProductLabel
    
    /// ProductLabel can savely unwrap the optional product
    ///
    ///  - Parameters:
    ///     - success: A bool indicating if the purchase was successful
    ///     - product: The product which should be purchased with this button
    ///     - productLabel: A view containing the label of the button if the transaction isn't in proccess or succeeded. **The product can be safely unwrapped in this child view**
    ///
    ///  - Warning: It's required to add a StoreManager as an EnvironmentObject to this view!
    init(success: Binding<Bool>, product: Binding<SKProduct?>, @ViewBuilder productLabel: @escaping () -> ProductLabel) {
        self._success = success
        self._product = product
        self.productLabel = productLabel
    }

    var body: some View {
        if let product = product {
            Button {
                if success {
                    dismiss()
                } else {
                    storeManager.purchaseProduct(product: product)
                }
            } label: {
                HStack {
                    Spacer()
                    if success {
                        Text("Thank you so much! \(Image(systemName: "heart.fill"))")
                    } else if let transactionState = storeManager.transactionState, transactionState == .purchasing {
                        ProgressView()
                    } else {
                        productLabel()
                    }
                    Spacer()
                }
            }
        }
    }
}
