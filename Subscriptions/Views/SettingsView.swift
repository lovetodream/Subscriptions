//
//  SettingsView.swift
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
import CoreData
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("useCloudKitSync") private var iCloudSync = false
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    @AppStorage("monthlyBudget") private var budget = 0.0
    @AppStorage("monthlyBudgetActive") private var budgetActive = false
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    @AppStorage("onlyRelevantSubscriptions") private var showOnlyRelevantSubscriptions = false
    @AppStorage("unlockWithBiometrics") private var unlockWithBiometrics = false
    @AppStorage("timeToReceiveNotifications") private var timeToReceiveNotifications = Date.now
    @AppStorage("sendNotificationsWithPriceTag") private var sendNotificationsWithPriceTag = true
    
    @State private var showPremiumIAP = false
    @State private var confirmErasing = false
    @State private var showTipJar = false
    @State private var showiCloudDisclaimer = false
    
    private enum Field: Int, Hashable {
        case budget
    }
    @FocusState private var focusedField: Field?
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \IgnoredBudgetMonth.firstOfMonth, ascending: true)], animation: .default)
    private var ignoredBudgetMonths: FetchedResults<IgnoredBudgetMonth>
    
    @State private var searchText = ""
    @State private var biometryType: LABiometryType?
    @State private var context: LAContext?
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return Locale.commonISOCurrencyCodes
        } else {
            return Locale.commonISOCurrencyCodes.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if lifetimePremium {
                    Section {
                        Toggle(isOn: $budgetActive) {
                            Text("Monthly Budget")
                        }
                        .onChange(of: budgetActive) { newValue in
                            if newValue {
                                focusedField = .budget
                            }
                        }
                        if budgetActive {
                            HStack {
                                TextField("0.00", value: $budget, formatter: numberFormatter)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .budget)
                                Text(currency.currencySymbol)
                            }
                            if ignoredBudgetMonths.count > 0 {
                                Button {
                                    ignoredBudgetMonths.forEach(viewContext.delete)
                                    try? viewContext.save()
                                    dismiss()
                                } label: {
                                    Label {
                                        Text("Clear ignored months")
                                        .foregroundColor(.label)
                                    } icon: {
                                        Image(systemName: "clear")
                                    }
                                }
                            }
                        }
                    } footer: {
                        Text("If your monthly bills exceed the defined budget you'll get notified.")
                    }
                }
                
                Section {
                    Picker(selection: $currency) {
                        SearchBar(text: $searchText, placeholder: "Search")
                        ForEach(searchResults, id: \.self) { c in
                           Text("\(c) (\(c.currencySymbol))")
                                    .id(c)
                        }
                    } label: {
                        Text("Currency")
                    }
                } footer: {
                    Text("This is a display only option and does not affect the cost of your subscriptions.")
                }
                
                Group {
                    Section {
                        Toggle(isOn: $iCloudSync) {
                            Label("iCloud Sync", systemImage: "icloud")
                        }
                        .onChange(of: iCloudSync) { newValue in
                            withAnimation {
                                if newValue && !lifetimePremium {
                                    iCloudSync = false
                                    showPremiumIAP.toggle()
                                } else if newValue {
                                    showiCloudDisclaimer = true
                                }
                            }
                        }
                    } footer: {
                        Text("Enabling iCloud Sync will allow your subscriptions to stay in sync across all your devices.")
                    }
                    
                    Section {
                        Toggle(isOn: $sendNotificationsWithPriceTag) {
                            Text("Include cost in notifications")
                        }
                        DatePicker("Time at which you receive notifications",
                                   selection: $timeToReceiveNotifications,
                                   displayedComponents: .hourAndMinute)
                    } footer: {
                        Text("You will receive all your notifications at \(timeToReceiveNotifications, style: .time). Except reminders to cancel a subscriptions, you can specify date and time for those individually.")
                    }
                    
                    Section {
                        Toggle(isOn: $showOnlyRelevantSubscriptions) {
                            Label("Only relevant subscriptions", systemImage: "eye.slash")
                        }
                    } footer: {
                        Text("Shows only relevant subscriptions for this month by default. This hides all subscriptions which aren't due for the rest of the month.")
                    }
                    
                    Section {
                        Toggle(isOn: $roundedIconBorders) {
                            Label("Rounded Borders on Icons", systemImage: "app")
                        }
                    }
                }
                
                if let biometryType = biometryType {
                    Section {
                        Toggle(isOn: $unlockWithBiometrics) {
                            switch biometryType {
                            case .touchID:
                                Label("Use Touch-ID to unlock the app", systemImage: "touchid")
                            case .faceID:
                                Label("Use Face-ID to unlock the app", systemImage: "faceid")
                            case .none:
                                Label("Use a PIN to unlock the app", systemImage: "lock")
                            @unknown default:
                                Label("Use a PIN to unlock the app", systemImage: "lock")
                            }
                        }
                    } footer: {
                        Text("Tip: You can long tap any price tag within the app to switch to private mode and vice versa. (This hides all prices)")
                    }
                    .onChange(of: unlockWithBiometrics) { newValue in
                        if let context = context {
                            if newValue {
                                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Activate device unlock") { success, error in
                                    if !success || error != nil {
                                        debugPrint(error as Any)
                                        unlockWithBiometrics = false
                                    }
                                }
                            } else {
                                context.invalidate()
                                
                                self.context = LAContext()
                            }
                        }
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://timozacherl.com")!) {
                        Label {
                            Text("Website")
                                .foregroundColor(.label)
                        } icon: {
                            Image(systemName: "safari")
                        }
                    }
                    Link(destination: URL(string: "mailto:timo@timozacherl.com")!) {
                        Label {
                            Text("Email")
                                .foregroundColor(.label)
                        } icon: {
                            Image(systemName: "envelope")
                        }
                    }
                } header: {
                    Text("Contact")
                } footer: {
                    Text("This app was made with \(Image(systemName: "heart.fill")) by an independent iOS developer called Timo.")
                }
                
                NavigationLink {
                    AcknowledgementView()
                } label: {
                    Label {
                        Text("Acknowledgements")
                    } icon: {
                        Text("👍")
                    }
                }
                
                Section {
                    if !lifetimePremium {
                        Button {
                            withAnimation {
                                showPremiumIAP.toggle()
                            }
                        } label: {
                            Label {
                                Text("Premium Version")
                                    .foregroundColor(.label)
                            } icon: {
                                Image(systemName: "bag")
                            }
                        }
                    } else {
                        Button {
                            withAnimation {
                                showTipJar.toggle()
                            }
                        } label: {
                            Label {
                                Text("Tip Jar")
                                    .foregroundColor(.label)
                            } icon: {
                                Image(systemName: "heart")
                                    .symbolVariant(.fill)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("Purchases")
                }
                
                Section {
                    Button {
                        withAnimation {
                            confirmErasing.toggle()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Erase all data")
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.red)
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("No third-party tracking or analytics services are used, and no personal data is collected or shared with anyone.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPremiumIAP) {
                PremiumIAPView()
                    .environmentObject(storeManager)
            }
            .sheet(isPresented: $showTipJar) {
                TipJarView()
                    .environmentObject(storeManager)
            }
            .actionSheet(isPresented: $confirmErasing) {
                ActionSheet(title: Text("Are you sure?"), message: Text("This will remove all your subscriptions and corresponding data from the app permanently."), buttons: [.cancel(), .destructive(Text("Erase all data"), action: {
                    deleteAllData("Item")
                    deleteAllData("Reminder")
                    deleteAllData("IgnoredBudgetMonth")
                    try! viewContext.save()
                    dismiss()
                })])
            }
            .alert("Information", isPresented: $showiCloudDisclaimer) {
                Button(role: .cancel) {
                    showiCloudDisclaimer = false
                } label: {
                    Text("Ok")
                }
            } message: {
                Text("It may take some time for iCloud to start syncing your data across your devices.")
            }
            .onAppear {
                context = LAContext()
                var error: NSError?
                if context!.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                    if error == nil {
                        withAnimation {
                            self.biometryType = context!.biometryType
                        }
                    }
                }
            }
        }
    }
    
    private func deleteAllData(_ entity: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try viewContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                viewContext.delete(objectData)
            }
        } catch let error {
            print("Delete all data in \(entity) error :", error)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
            SettingsView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(StoreManager())
    }
}

extension Date: RawRepresentable {
    private static let formatter = ISO8601DateFormatter()
    
    public var rawValue: String {
        Date.formatter.string(from: self)
    }
    
    public init?(rawValue: String) {
        self = Date.formatter.date(from: rawValue) ?? Date()
    }
}
