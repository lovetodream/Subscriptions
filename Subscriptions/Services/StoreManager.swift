//
//  StoreManager.swift
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

import Foundation
import StoreKit
import CoreData

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var productIDs: [String] = {
        var array1 = [Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String]
        var array2 = Bundle.main.object(forInfoDictionaryKey: "tipIAPs") as! [String]
        array1.append(contentsOf: array2)
        return array1
    }()
    @Published var availableProducts = [SKProduct]()
    @Published var transactionState: SKPaymentTransactionState?
    var transactionInProgress: Bool {
        transactionState == .purchasing
    }
    
    var request: SKProductsRequest!
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Did receive response")
            
        if !response.products.isEmpty {
            for fetchedProduct in response.products {
                if !self.availableProducts.contains(where: { $0.productIdentifier == fetchedProduct.productIdentifier }) {
                    DispatchQueue.main.async {
                        self.availableProducts.append(fetchedProduct)
                    }
                }
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Request did fail: \(error)")
    }
    
    func getProducts(ids: [String]? = nil) {
        let productIDs = ids ?? productIDs
        print("Start requesting products ...")
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                transactionState = .purchasing
            case .purchased:
                print(transaction.payment.productIdentifier)
                if transaction.payment.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String {
                    UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                } else if (Bundle.main.object(forInfoDictionaryKey: "tipIAPs") as! [String]).contains(where: { $0 == transaction.payment.productIdentifier }) {
                    storeTipPurchase(transaction)
                }
                queue.finishTransaction(transaction)
                transactionState = .purchased
            case .restored:
                print(transaction.payment.productIdentifier)
                if transaction.payment.productIdentifier == Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String {
                    UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                }
                queue.finishTransaction(transaction)
                transactionState = .restored
            case .failed, .deferred:
                print("Payment Queue Error: \(String(describing: transaction.error))")
                queue.finishTransaction(transaction)
                transactionState = .failed
            default:
                queue.finishTransaction(transaction)
            }
        }
    }
    
    func purchaseProduct(product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("User can't make payment.")
        }
    }
    
    func restoreProducts() {
        print("Restoring products ...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func storeTipPurchase(_ transaction: SKPaymentTransaction) {
        let context = PersistenceController.shared.container.viewContext
        let affectedProduct = availableProducts.first(where: { $0.productIdentifier == transaction.payment.productIdentifier })
        let newTip = Tip(context: context)
        newTip.timestamp = transaction.transactionDate
        newTip.transactionID = transaction.transactionIdentifier
        newTip.productID = transaction.payment.productIdentifier
        newTip.currency = affectedProduct?.priceLocale.currencyCode
        newTip.price = affectedProduct?.price
        try? context.save()
    }
}
