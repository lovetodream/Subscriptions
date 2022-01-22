// 
//  RestoreButton.swift
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

/// Button to restore purchases with a "Restore Purchase" label
///
///  - Warning: It's required to add a StoreManager as an EnvironmentObject to this view!
struct RestoreButton: View {
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        Button {
            withAnimation {
                storeManager.restoreProducts()
            }
        } label: {
            Text("Restore Purchase")
        }
        .buttonStyle(.borderless)
    }
}
