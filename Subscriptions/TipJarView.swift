//
//  TipJarView.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 16.01.22.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: SKProduct?
    
    private var availableProducts: [SKProduct] {
        storeManager.availableProducts.filter { $0.productIdentifier != Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String }.sorted { $0.price.decimalValue < $1.price.decimalValue }
    }
    
    @State private var success = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Text("Tip Jar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.vertical, 30)
                        .padding(.top, 30)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 500))]) {
                        ForEach(availableProducts, id: \.productIdentifier) { product in
                            Button {
                                withAnimation {
                                    selectedProduct = product
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(product.price.decimalValue, format: .currency(code: product.priceLocale.currencyCode ?? Locale.current.currencyCode!))
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
            
            if let selectedProduct = selectedProduct {
                VStack {
                    Button {
                        if success {
                            dismiss()
                        } else {
                            storeManager.purchaseProduct(product: selectedProduct)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if success {
                                Text("Thank you so much! \(Image(systemName: "heart.fill"))")
                            } else if let transactionState = storeManager.transactionState, transactionState == .purchasing {
                                ProgressView()
                            } else {
                                Text(selectedProduct.localizedTitle) + Text(" (\(selectedProduct.price.decimalValue, format: .currency(code: selectedProduct.priceLocale.currencyCode ?? Locale.current.currencyCode!)))")
                            }
                            Spacer()
                        }
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

struct TipJarView_Previews: PreviewProvider {
    static var previews: some View {
        TipJarView()
            .environmentObject(StoreManager())
    }
}
