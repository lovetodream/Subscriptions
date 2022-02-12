//
//  ContentView.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 14.12.21.
//
//  Copyright © 2021 Timo Zacherl. All rights reserved.
//
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
//

import SwiftUI
import StoreKit
import CoreData
import LocalAuthentication

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    @AppStorage("monthlyBudget") private var budget = 0.0
    @AppStorage("monthlyBudgetActive") private var budgetActive = false
    @AppStorage("onlyRelevantSubscriptions") private var showOnlyRelevantSubscriptions = false
    @AppStorage("privacyMode") private var privacyMode = false
    
    @AppStorage("unlockWithBiometrics") private var unlockWithBiometrics = false
    // locked is only taking affect if unlockWithBiometrics is true
    @State private var locked = true
    
    @AppStorage("timeToReceiveNotifications") private var timeToReceiveNotifications = Date.now
    @AppStorage("sendNotificationsWithPriceTag") private var sendNotificationsWithPriceTag = true
    
    @ObservedObject var notificationScheduler = NotificationScheduler.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        predicate: NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "active == %@", NSNumber(value: true)), NSPredicate(format: "deactivationDate == %@ OR deactivationDate >= %@", NSNull(), NSDate(timeIntervalSince1970: Date.now.timeIntervalSince1970))]),
        animation: .default)
    private var items: FetchedResults<Item>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], predicate: NSPredicate(format: "active == %@ OR deactivationDate < %@", NSNumber(value: false), NSDate(timeIntervalSince1970: Date.now.timeIntervalSince1970)), animation: .default)
    private var archivedItems: FetchedResults<Item>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \IgnoredBudgetMonth.firstOfMonth, ascending: true)], predicate: NSPredicate(format: "firstOfMonth == %@", NSDate(timeIntervalSince1970: Date.now.startOfMonth().timeIntervalSince1970)), animation: .default)
    private var ignoredBudgetMonths: FetchedResults<IgnoredBudgetMonth>
    
    let publisher = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
    
    @StateObject var storeManager = StoreManager()
    
    @State private var addSubscription = false
    @State private var showSettings = false
    @State private var showPremiumIAP = false
    @State private var highlightAddButton: CGFloat = 0
    @State private var ignoreOnlyRelevantFlag = false
    
    @State private var searchText = ""
    
    var searchResult: [Item] {
        if searchText.isEmpty {
            return items.filter { item in
                if showOnlyRelevantSubscriptions && !ignoreOnlyRelevantFlag {
                    if let nextBill = getNextBill(item, circle: BillingOption(item.billing)) {
                        let endOfMonth = Date.now.endOfMonth()
                        return nextBill <= endOfMonth && nextBill >= Calendar.current.startOfDay(for: .now)
                    }
                    return false
                }
                return true
            }.sorted { previous, next in
                if let previousNextBill = getNextBill(previous, circle: BillingOption(previous.billing)),
                    let nextNextBill = getNextBill(next, circle: BillingOption(next.billing)) {
                    return previousNextBill < nextNextBill
                }
                return previous.timestamp! < next.timestamp!
             }
        }
        
        return items.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false }
    }
    
    private var currentMonthCost: Decimal {
        return calculateCostForRestOfCurrentMonth(for: items)
    }
    
    private var monthFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency.currencySymbol
        formatter.internationalCurrencySymbol = currency.currencySymbol
        return formatter
    }

    var body: some View {
        NavigationView {
            List {
                if !privacyMode, let cost = calculateCostForRestOfCurrentMonth(for: items, fullMonth: true), let budget = Decimal(budget), budgetActive, cost > budget, !ignoredBudgetMonths.contains(where: { $0.firstOfMonth == .now.startOfMonth() }) {
                    Section {
                        NavigationLink {
                            BillView(showSettings: $showSettings, cost: cost, budget: budget)
                                .environmentObject(notificationScheduler)
                        } label: {
                            Label {
                                Text("This months bill exceeds your budget by \((cost - budget) as NSDecimalNumber, formatter: currencyFormatter).")
                            } icon: {
                                Image(systemName: "exclamationmark.circle")
                            }
                        }
                        .listRowBackground(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                        .foregroundColor(.white)
                    } header: {
                        Text("Information")
                    }
                }
                
                if items.contains(where: { $0.pinned }) {
                    Section {
                        ForEach(items.filter { $0.pinned }) { item in
                            NavigationLink {
                                SubscriptionDetailView(item: item)
                                    .environmentObject(notificationScheduler)
                            } label: {
                                ItemRow(item: item, context: .pinned)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        item.pinned.toggle()
                                        try? viewContext.save()
                                    }
                                } label: {
                                    item.pinned ? Label("Unpin", systemImage: "pin.slash") : Label("Pin", systemImage: "pin")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        item.active.toggle()
                                        item.deactivationDate = item.active ? nil : .now
                                        try? viewContext.save()
                                    }
                                } label: {
                                    item.active ? Label("Pause", systemImage: "pause") : Label("Reactivate", systemImage: "play")
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } header: {
                        Text("Pinned")
                    }
                }
                
                Section {
                    if items.count > 0 {
                        ForEach(searchResult) { item in
                            NavigationLink {
                                SubscriptionDetailView(item: item)
                                    .environmentObject(notificationScheduler)
                            } label: {
                                ItemRow(item: item)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        item.pinned.toggle()
                                        try? viewContext.save()
                                    }
                                } label: {
                                    item.pinned ? Label("Unpin", systemImage: "pin.slash") : Label("Pin", systemImage: "pin")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        item.active.toggle()
                                        item.deactivationDate = item.active ? nil : .now
                                        try? viewContext.save()
                                    }
                                } label: {
                                    item.active ? Label("Pause", systemImage: "pause") : Label("Reactivate", systemImage: "play")
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } else {
                        Button {
                            withAnimation {
                                highlightAddButton += 1
                            }
                        } label: {
                            Text("Add your first Subscription with the \(Image(systemName: "plus")) button.")
                        }
                    }
                } header: {
                    Text("Due this month: \(currentMonthCost as NSDecimalNumber, formatter: currencyFormatter)")
                        .privacySensitive()
                }
                
                if showOnlyRelevantSubscriptions {
                    Button {
                        withAnimation {
                            ignoreOnlyRelevantFlag.toggle()
                        }
                    } label: {
                        if ignoreOnlyRelevantFlag {
                            Label("Show only relevant subscriptions", systemImage: "eye.slash")
                        } else {
                            Label("Show all active subscriptions", systemImage: "eye")
                        }
                    }
                }
                
                if archivedItems.count > 0 {
                    NavigationLink {
                        List {
                            ForEach(archivedItems) { archivedItem in
                                NavigationLink {
                                    SubscriptionDetailView(item: archivedItem)
                                        .environmentObject(notificationScheduler)
                                } label: {
                                    ItemRow(item: archivedItem)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteItem(archivedItem, in: viewContext)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        withAnimation {
                                            archivedItem.active = true
                                            archivedItem.deactivationDate = nil
                                            try? viewContext.save()
                                        }
                                    } label: {
                                        Label("Resume", systemImage: "play")
                                    }
                                    .tint(.green)
                                }
                            }
                            .onDelete(perform: deleteArchivedItems)
                        }
                        .navigationTitle("Inactive Subscriptions")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                EditButton()
                            }
                        }
                    } label: {
                        Label {
                            if archivedItems.count != 1 {
                                Text("Show \(archivedItems.count) inactive Subscriptions")
                            } else {
                                Text("Show \(archivedItems.count) inactive Subscription")
                            }
                        } icon: {
                            Image(systemName: "archivebox")
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        addSubscription.toggle()
                    } label: {
                        Label("Add Subscription", systemImage: "plus")
                    }
                    .modifier(Bounce(animatableData: highlightAddButton))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            showSettings.toggle()
                        }
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Subscriptions")
            VStack {
                Text("Select a subscription")
                Button {
                    addSubscription.toggle()
                } label: {
                    Text("or add a new one")
                }
            }
        }
        .sheet(isPresented: $addSubscription) {
            SubscriptionForm(currentActiveSubscriptions: items.count)
                .environmentObject(notificationScheduler)
                .environmentObject(storeManager)
        }
        .sheet(isPresented: $showSettings) {
            viewContext.refreshAllObjects()
        } content: {
            SettingsView()
                .environmentObject(storeManager)
        }
        .sheet(isPresented: $showPremiumIAP) {
            PremiumIAPView()
                .environmentObject(storeManager)
        }
        .onAppear {
            storeManager.getProducts()
            SKPaymentQueue.default().add(storeManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { output in
            viewContext.refreshAllObjects()
        }
        .if(privacyMode) {
            $0.redacted(reason: .privacy)
        }
        .if(locked && unlockWithBiometrics) {
            $0.overlay {
                ZStack {
                    Rectangle()
                        .fill(.thinMaterial)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        Button {
                            let context = LAContext()
                            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, error in
                                debugPrint(error as Any)
                                if success {
                                    withAnimation {
                                        locked = false
                                    }
                                }
                            }
                        } label: {
                            Text("Unlock Abonementi")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newValue in
            switch newValue {
            case .inactive, .background:
                notificationScheduler.removeDeliveredNotifications()
                
                Task {
                    await notificationScheduler.scheduleNotifications(for: items, at: timeToReceiveNotifications, with: sendNotificationsWithPriceTag, and: currencyFormatter)
                    
                    print("Pending...")
                    print(await UNUserNotificationCenter.current().pendingNotificationRequests())
                }
                
                locked = true
            case .active:
                notificationScheduler.removeDeliveredNotifications()
                
                Task {
                    await notificationScheduler.scheduleNotifications(for: items, at: timeToReceiveNotifications, with: sendNotificationsWithPriceTag, and: currencyFormatter)
                    
                    print("Pending...")
                    print(await UNUserNotificationCenter.current().pendingNotificationRequests())
                }
                
                if locked && unlockWithBiometrics {
                    let context = LAContext()
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock the app") { success, error in
                        debugPrint(error as Any)
                        if success {
                            withAnimation {
                                locked = false
                            }
                        }
                    }
                }
            @unknown default:
                break
            }
        }
        .onShake {
            withAnimation {
                privacyMode.toggle()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            deleteAtOffset(offsets, on: items, with: viewContext)
        }
    }
    
    private func deleteArchivedItems(offsets: IndexSet) {
        withAnimation {
            deleteAtOffset(offsets, on: archivedItems, with: viewContext)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct BillView: View {
    init(showSettings: Binding<Bool>, cost: Decimal, budget: Decimal) {
        self._showSettings = showSettings
        self.cost = cost
        self.budget = budget
    }
    
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    
    @Environment(\.managedObjectContext) var viewContext
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        predicate: NSCompoundPredicate(type: .and, subpredicates: [
            NSPredicate(format: "active == %@", NSNumber(value: true)),
            NSPredicate(format: "deactivationDate == %@ OR deactivationDate >= %@", NSNull(), NSDate(timeIntervalSince1970: Date.now.timeIntervalSince1970))
        ]),
        animation: .default)
    var items: FetchedResults<Item>
    
    @Binding var showSettings: Bool
    
    private var monthFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency.currencySymbol
        formatter.internationalCurrencySymbol = currency.currencySymbol
        return formatter
    }
    
    var cost: Decimal
    var budget: Decimal

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Bill for \(Date.now, formatter: monthFormatter)")
                    Spacer()
                    Text(cost as NSDecimalNumber, formatter: currencyFormatter)
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Budget")
                    Spacer()
                    Text(budget as NSDecimalNumber, formatter: currencyFormatter)
                        .fontWeight(.semibold)
                }
                HStack {
                    Spacer()
                    Text((budget - cost) as NSDecimalNumber, formatter: currencyFormatter)
                }
                .listRowSeparatorTint(Color.secondaryLabel)
            }
            
            Button {
                showSettings.toggle()
            } label: {
                Label("Edit Budget", systemImage: "creditcard")
            }
            
            Button {
                withAnimation {
                    let newItem = IgnoredBudgetMonth(context: viewContext)
                    newItem.firstOfMonth = Date.now.startOfMonth()
                    try? viewContext.save()
                }
            } label: {
                Label("Ignore Budget for this month", systemImage: "eye.slash")
            }
            
            Section {
                ForEach(items) { item in
                    if inCurrentMonth(item, circle: BillingOption(item.billing), fullMonth: true) {
                        NavigationLink {
                            SubscriptionDetailView(item: item)
                                .environmentObject(notificationScheduler)
                        } label: {
                            ItemRow(item: item, context: .budget)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    item.pinned.toggle()
                                    try? viewContext.save()
                                }
                            } label: {
                                item.pinned ? Label("Unpin", systemImage: "pin.slash") : Label("Pin", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    item.active.toggle()
                                    item.deactivationDate = item.active ? nil : .now
                                    try? viewContext.save()
                                }
                            } label: {
                                item.active ? Label("Pause", systemImage: "pause") : Label("Reactivate", systemImage: "play")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            } header: {
                Text("Due Subscriptions")
            }
        }
        .navigationTitle("Budget")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            deleteAtOffset(offsets, on: items, with: viewContext)
        }
    }
    
}
