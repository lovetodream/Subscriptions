// 
//  LicenseView.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 29.01.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct LicenseView: View {
    @Environment(\.dismiss) var dismiss
    
    var license: License
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(license.content)
                    .lineLimit(.none)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .padding()
            }
            .navigationTitle(license.product)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton(fill: .secondarySystemBackground) {
                        withAnimation {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView(license: License(product: "", content: "", url: URL(string: "https://starwars.com")!))
    }
}
