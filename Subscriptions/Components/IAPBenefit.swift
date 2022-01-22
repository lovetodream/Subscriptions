// 
//  IAPBenefit.swift
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

struct IAPBenefit<Symbol: View>: View {
    var previewFeature: Bool
    var headline: Text
    var subheadline: Text
    var symbol: () -> Symbol
    
    
    /// IAP benefit label with headline, subheadline and a symbol (preferably sf symbol)
    ///
    /// - Parameters:
    ///   - previewFeature: uses secondaryLabel as foregroundColor if true
    ///   - headline: text with font headline
    ///   - subheadline: text with font subheadline
    ///   - symbol: symbol on the side of the text views, ideally a sf symbol
    init(previewFeature: Bool = false, headline: Text, subheadline: Text, @ViewBuilder symbol: @escaping () -> Symbol) {
        self.previewFeature = previewFeature
        self.headline = headline
        self.subheadline = subheadline
        self.symbol = symbol
    }
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                headline
                    .font(.headline)
                subheadline
                    .font(.subheadline)
            }
            .foregroundColor(previewFeature ? .secondaryLabel : .label)
            Spacer()
        } icon: {
            symbol()
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
