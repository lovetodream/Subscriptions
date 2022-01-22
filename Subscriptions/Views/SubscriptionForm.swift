//
//  SubscriptionForm.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 07.01.22.
//
//  Copyright © 2022 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import Foundation
import SwiftUI
import FaviconFinder

struct SubscriptionForm: View {
    init(currentActiveSubscriptions: Int) {
        self.currentActiveSubscriptions = currentActiveSubscriptions
    }
    
    init(item: Item) {
        self.item = item
        self._title = .init(initialValue: item.title ?? "")
        self._url = .init(initialValue: item.serviceUrl)
        self._note = .init(initialValue: item.note ?? "")
        self._cost = .init(initialValue: item.cost?.doubleValue ?? 0.0)
        self._billingCircle = .init(initialValue: BillingOption(item.billing))
        self._lastBillDate = .init(initialValue: item.lastBillDate ?? .now)
        self._color = .init(initialValue: item.color != nil && !item.color!.isEmpty ? Color(hex: item.color!) ?? .accentColor : .accentColor)
        self._cancellationUrl = .init(initialValue: item.cancellationUrl?.absoluteString ?? "")
        self._customBillingCircle = .init(initialValue: Int(item.billing))
        self._withDeactivationDate = .init(initialValue: item.deactivationDate != nil)
        self._deactivationDate = .init(initialValue: item.deactivationDate ?? .now)
        self._step = .init(initialValue: 2)
        self._icon = .init(initialValue: item.icon != nil ? UIImage(data: item.icon!) ?? UIImage() : UIImage())
        self._iconIsSfSymbol = .init(initialValue: item.systemImage != nil)
        self._iconSfSymbol = .init(initialValue: item.systemImage ?? "")
        self._editMode = .init(initialValue: true)
        self.currentActiveSubscriptions = 0
    }
    
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    
    @State private var titleOrUrl = ""
    @State private var title = ""
    @State private var url: URL? = nil
    @State private var note = ""
    @State private var cost: Double = 0.0
    @State private var billingCircle: BillingOption = .monthly
    @State private var lastBillDate = Date.now
    @State private var color = Color.accentColor
    @State private var showAdvancedOptions = false
    @State private var cancellationUrl = ""
    @State private var customBillingCircle = 2
    @State private var withDeactivationDate = false
    @State private var deactivationDate = Date.now
    @State private var step: Int? = nil
    @State private var icon: UIImage = UIImage()
    @State private var iconIsSfSymbol = true
    @State private var iconSfSymbol = "questionmark.square.dashed"
    @State private var showIconPicker = false
    @State private var purchasePremium = false
    @State private var editMode = false
    private var item: Item? = nil
    
    var currentActiveSubscriptions: Int
    @FocusState private var focusedField: Field?
    
    var suggestionString: AttributedString {
        try! AttributedString(markdown: "The list of suggestions gets updated on a regular basis. If you think a particular suggestion should be added, [you can do so here](mailto:timo@timozacherl.com?subject=Abonementi%20-%20Suggestion%20Proposal%20-%20\(titleOrUrl.fastestEncoding)).")
    }
    
    var canAddSubscription: Bool {
        currentActiveSubscriptions < 5 || lifetimePremium
    }
    
    var body: some View {
        NavigationView {
            if editMode {
                SubscriptionDetailsForm(dismiss: _dismiss,
                                        item: item,
                                        title: $title,
                                        note: $note,
                                        cost: $cost,
                                        editMode: $editMode,
                                        showAdvancedOptions: $showAdvancedOptions,
                                        billingCircle: $billingCircle,
                                        customBillingCircle: $customBillingCircle,
                                        color: $color,
                                        lastBillDate: $lastBillDate,
                                        showIconPicker: $showIconPicker,
                                        icon: $icon,
                                        currency: $currency,
                                        url: $url,
                                        cancellationUrl: $cancellationUrl,
                                        deactivationDate: $deactivationDate,
                                        withDeactivationDate: $withDeactivationDate,
                                        iconIsSfSymbol: $iconIsSfSymbol,
                                        iconSfSymbol: $iconSfSymbol)
            } else {
                Form {
                    if !canAddSubscription {
                        Section {
                            Text("You have reached the limit of free active Subscriptions")
                            Button {
                                purchasePremium.toggle()
                            } label: {
                                Label("Unlock more", systemImage: "bag")
                            }
                        } header: {
                            Text("Disclaimer")
                        } footer: {
                            Text("Purchasing Premium helps the developer of this app.")
                        }
                    }
                    
                    Section {
                        TextField("Title or URL", text: $titleOrUrl)
                            .focused($focusedField, equals: .titleOrUrl)
                            .submitLabel(.continue)
                            .onSubmit {
                                submitStep1()
                            }
                            .task {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    focusedField = .titleOrUrl
                                }
                            }
                            .disabled(!canAddSubscription)
                    }
                
                    // TODO: add suggestions in a later release
                    if titleOrUrl.count < 0 {
                        Section {
                            Text("No potential matches found...")
                        } header: {
                            Text("Suggestions")
                        } footer: {
                            Text(suggestionString)
                        }
                    }
                
                    Button(action: submitStep1) {
                        HStack {
                            Text("Continue")
                            NavigationLink(tag: 2, selection: $step) {
                                SubscriptionDetailsForm(dismiss: _dismiss,
                                                        title: $title,
                                                        note: $note,
                                                        cost: $cost,
                                                        editMode: $editMode,
                                                        showAdvancedOptions: $showAdvancedOptions,
                                                        billingCircle: $billingCircle,
                                                        customBillingCircle: $customBillingCircle,
                                                        color: $color,
                                                        lastBillDate: $lastBillDate,
                                                        showIconPicker: $showIconPicker,
                                                        icon: $icon,
                                                        currency: $currency,
                                                        url: $url,
                                                        cancellationUrl: $cancellationUrl,
                                                        deactivationDate: $deactivationDate,
                                                        withDeactivationDate: $withDeactivationDate,
                                                        iconIsSfSymbol: $iconIsSfSymbol,
                                                        iconSfSymbol: $iconSfSymbol)
                            } label: {
                                EmptyView()
                            }
                        }
                    }
                    .disabled(!canAddSubscription)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
                .navigationTitle("Add Subscription")
            }
        }
        .sheet(isPresented: $showIconPicker) {
            IconPicker(image: $icon,
                       systemImage: $iconSfSymbol,
                       isSystemImage: $iconIsSfSymbol,
                       color: $color)
        }
        .sheet(isPresented: $purchasePremium) {
            PremiumIAPView()
                .environmentObject(storeManager)
        }
    }
    
    private func submitStep1() {
        withAnimation {
            if let url = URL(string: titleOrUrl) {
                self.url = url
                if url.scheme == nil {
                    self.url = URL(string: "https://\(url.absoluteString)")
                }
                self.title = self.url?.host ?? ""
                Task {
                    if let selfUrl = self.url, let cgImage = try? await FaviconFinder(url: selfUrl).downloadFavicon().image.cgImage {
                        self.icon = UIImage(cgImage: cgImage)
                        self.iconIsSfSymbol = false
                        if let uiColor = self.icon.averageColor {
                            self.color = Color(uiColor: uiColor)
                        }
                    }
                    
                }
            } else {
                self.title = titleOrUrl
            }
            
            step = 2
        }
    }
}

/// Fields shared by the SubscriptionForm and SubscriptionDetailsForm
enum Field: Int, Hashable {
    case titleOrUrl
    case cost
    case cancellationUrl
}

struct SubscriptionForm_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionForm(currentActiveSubscriptions: 6)
            SubscriptionForm(currentActiveSubscriptions: 6)
                .preferredColorScheme(.dark)
        }
    }
}
