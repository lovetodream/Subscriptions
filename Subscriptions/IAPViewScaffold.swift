//
//  IAPViewScaffold.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 21.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import StoreKit

struct IAPViewScaffold<Content: View, PrimaryAction: View>: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var success: Bool
    
    @Binding var selectedProduct: SKProduct?
    
    var title: Text
    
    var content: () -> Content
    var primaryAction: () -> PrimaryAction

    init(success: Binding<Bool>,
         selectedProduct: Binding<SKProduct?>,
         title: Text,
         @ViewBuilder primaryAction: @escaping () -> PrimaryAction,
         @ViewBuilder content: @escaping () -> Content) {
        self._success = success
        self._selectedProduct = selectedProduct
        self.title = title
        self.content = content
        self.primaryAction = primaryAction
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    title
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, 30)
                        .padding(.top, 30)
                    
                    content()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            
            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.secondaryLabel)
                        .opacity(0.75)
                        .frame(width: 75, height: 5)
                        .padding(10)
                    Spacer()
                }
                .background(.background)
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Link(destination: URL(string: "https://timozacherl.com/apps/#/legal")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                    }
                    .controlSize(.large)
                    .padding()
                    .background(.background)
                    .cornerRadius(10)
                }
                Spacer()
            }
            
            if selectedProduct != nil {
                VStack {
                    Group {
                        primaryAction()
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(storeManager.transactionInProgress)
                    .animation(.default, value: storeManager.transactionInProgress)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .onChange(of: storeManager.transactionState) { newValue in
            if newValue == .purchased {
                success = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        }
    }
}

struct IAPViewScaffold_Previews: PreviewProvider {
    static var previews: some View {
        IAPViewScaffold(
            success: .constant(false),
            selectedProduct: .constant(nil),
            title: Text("Buy this fancy stuff!")) {
                Button("May the force be with me") {
                    print("You got it")
                }
        } content: {
            VStack {
                Text("This adds Chewbacca to your crew")
                
                Text("This beats Darth Sidious with one purchase")
            }
        }

    }
}
