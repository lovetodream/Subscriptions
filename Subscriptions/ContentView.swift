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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    @AppStorage("monthlyBudget") private var budget = 0.0
    @AppStorage("monthlyBudgetActive") private var budgetActive = false

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
    
    @State private var searchText = ""
    
    // Little hack here
    @State private var significantTimeChanges = 0
    
    var searchResult: [Item] {
        if searchText.isEmpty {
            return items.reversed()
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
                if let cost = calculateCostForRestOfCurrentMonth(for: items, fullMonth: true), let budget = Decimal(budget), budgetActive, cost > budget, !ignoredBudgetMonths.contains(where: { $0.firstOfMonth == .now.startOfMonth() }) {
                    Section {
                        NavigationLink {
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
                }
                
                if archivedItems.count > 0 {
                    NavigationLink {
                        List {
                            ForEach(archivedItems) { archivedItem in
                                NavigationLink {
                                    SubscriptionDetailView(item: archivedItem)
                                } label: {
                                    ItemRow(item: archivedItem)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteItem(archivedItem)
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
            print(output)
            significantTimeChanges += 1
        }
    }
    
    func calculateCostForRestOfCurrentMonth(for items: FetchedResults<Item>, fullMonth: Bool = false) -> Decimal {
        let today = fullMonth ? .now.startOfMonth().addingTimeInterval(TimeInterval(60 * 60 * 24)) : Calendar.current.startOfDay(for: .now)
        let startOfCurrentMonth = today.startOfMonth()
        let endOfCurrentMonth = today.endOfMonth()
        let remainingDays = Calendar.current.numberOfDaysBetween(today, and: endOfCurrentMonth) + (fullMonth ? 1 : 0)
        var fullCost: Decimal = 0
        for item in items {
            let billing = BillingOption(item.billing)
            if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
                switch billing {
                case .daily:
                    fullCost += Decimal(remainingDays) * cost
                case .weekly:
                    let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
                    var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
                    if nextBilling.compare(today) == .orderedAscending {
                        nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
                    }
                    let occurencies = Calendar.current.dateComponents([.weekday], from: nextBilling, to: today.endOfMonth()).weekday! / 7
                    fullCost += Decimal(occurencies) * cost
                case .monthly:
                    var components = DateComponents()
                    components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
                    let currentMonthBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
                    if currentMonthBilling.compare(today) != .orderedAscending && currentMonthBilling.compare(endOfCurrentMonth) != .orderedDescending {
                        fullCost += cost
                    }
                case .quarterly:
                    var currentDateAtLoop = firstBilling
                    var components = DateComponents()
                    components.month = 3
                    while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                        if currentDateAtLoop.compare(today) != .orderedAscending {
                            fullCost += cost
                        }
                        currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
                    }
                case .everySixMonths:
                    var currentDateAtLoop = firstBilling
                    var components = DateComponents()
                    components.month = 6
                    while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                        if currentDateAtLoop.compare(today) != .orderedAscending {
                            fullCost += cost
                        }
                        currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
                    }
                case .annually:
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
                    components.year = Calendar.current.component(.year, from: today)
                    let currentYearBilling = Calendar.current.date(from: components)!
                    if currentYearBilling.compare(today) != .orderedAscending && currentYearBilling.startOfMonth() == startOfCurrentMonth {
                        fullCost += cost
                    }
                case .custom:
                    let roundedBilling = Int(item.billing.rounded(.down))
                    var currentDateAtLoop = firstBilling
                    while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                        if currentDateAtLoop.compare(today) != .orderedAscending {
                            fullCost += cost
                        }
                        currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
                    }
                }
            }
        }
        
        return fullCost
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
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            viewContext.delete(item)
            try? viewContext.save()
        }
    }
}

fileprivate func deleteAtOffset(_ offsets: IndexSet, on items: FetchedResults<Item>, with context: NSManagedObjectContext) {
    offsets.map { items[$0] }.forEach(context.delete)

    do {
        try context.save()
    } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day!
    }
}

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, second: -1), to: self.startOfMonth())!
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

struct ItemRow: View {
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    
    @ObservedObject var item: Item
    
    enum DisplayContext {
        case normal
        case pinned
        case archived
        case budget
    }
    var context: DisplayContext = .normal
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency.currencySymbol
        formatter.internationalCurrencySymbol = currency.currencySymbol
        return formatter
    }
    
    var body: some View {
        Label {
            Text(item.title ?? "Unnamed")
                .lineLimit(1)
            if item.pinned && context == .normal {
                Image(systemName: "pin")
                    .imageScale(.small)
                    .foregroundColor(.secondaryLabel)
            }
            Spacer()
            if let cost = item.cost?.decimalValue {
                Text(cost as NSDecimalNumber, formatter: currencyFormatter)
                    .foregroundColor(inCurrentMonth(item, circle: BillingOption(item.billing)) || context == .budget ? .label : .secondaryLabel)
            }
        } icon: {
            if let systemImage = item.systemImage, !systemImage.isEmpty {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
            } else if let data = item.icon, let icon = UIImage(data: data) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .if(roundedIconBorders) {
                        $0.cornerRadius(2)
                    }
            } else {
                Image(systemName: "questionmark")
                    .symbolVariant(.square)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 20, height: 20)
                    .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
            }
        }
    }
}

// MARK: View functions

func getPreviousBill(_ item: Item, circle: BillingOption) -> Date? {
    let today = Calendar.current.startOfDay(for: .now)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: -1, to: today)
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var previousBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if previousBilling.compare(today) == .orderedDescending {
                previousBilling = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: previousBilling)!
            }
            return previousBilling
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            var previousBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: today)!
            if previousBilling.compare(today) == .orderedDescending {
                previousBilling = Calendar.current.date(byAdding: .month, value: -1, to: previousBilling)!
            }
            return previousBilling
        case .quarterly:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 3
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            components.month = -3
            currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            return currentDateAtLoop
        case .everySixMonths:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 6
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            components.month = -6
            currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            return currentDateAtLoop
        case .annually:
            var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
            components.year = Calendar.current.component(.year, from: today)
            let currentYearBilling = Calendar.current.date(from: components)!
            if currentYearBilling.compare(today) == .orderedAscending {
                return currentYearBilling
            } else {
                return Calendar.current.date(byAdding: .year, value: -1, to: currentYearBilling)!
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
            currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling * -1, to: currentDateAtLoop)!
            return currentDateAtLoop
        }
    }
    
    return nil
}

func getNextBill(_ item: Item, circle: BillingOption) -> Date? {
    let today = Calendar.current.startOfDay(for: .now)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return today
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
            }
            return nextBilling
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            var nextBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .month, value: 1, to: nextBilling)!
            }
            return nextBilling
        case .quarterly:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 3
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        case .everySixMonths:
            var currentDateAtLoop = firstBilling
            var components = DateComponents()
            components.month = 6
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: components, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        case .annually:
            var components = Calendar.current.dateComponents([.year, .month, .day], from: firstBilling)
            components.year = Calendar.current.component(.year, from: today)
            let currentYearBilling = Calendar.current.date(from: components)!
            if currentYearBilling.compare(today) != .orderedAscending {
                return currentYearBilling
            } else {
                return Calendar.current.date(byAdding: .year, value: 1, to: currentYearBilling)!
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(today) != .orderedDescending {
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
            return currentDateAtLoop
        }
    }
    
    return nil
}

func inCurrentMonth(_ item: Item, circle: BillingOption, fullMonth: Bool = false) -> Bool {
    let today = fullMonth ? .now.startOfMonth().addingTimeInterval(TimeInterval(60 * 60 * 24)) : Calendar.current.startOfDay(for: .now)
    let startOfCurrentMonth = today.startOfMonth()
    let endOfCurrentMonth = today.endOfMonth()
    let remainingDays = Calendar.current.numberOfDaysBetween(today, and: endOfCurrentMonth) + (fullMonth ? 1 : 0)
    if let firstBilling = item.lastBillDate, let cost = item.cost?.decimalValue, cost > Decimal(0.0) {
        switch circle {
        case .daily:
            return remainingDays > 0
        case .weekly:
            let weekdayOfFirstBill = Calendar.current.dateComponents([.weekday], from: firstBilling).weekday!
            var nextBilling = Calendar.current.date(bySetting: .weekday, value: weekdayOfFirstBill, of: today)!
            if nextBilling.compare(today) == .orderedAscending {
                nextBilling = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextBilling)!
            }
            let occurencies = Calendar.current.dateComponents([.weekday], from: nextBilling, to: today.endOfMonth()).weekday! / 7
            return occurencies > 0
        case .monthly:
            var components = DateComponents()
            components.day = Calendar.current.dateComponents([.day], from: firstBilling).day!
            let currentMonthBilling = Calendar.current.date(bySetting: .day, value: components.day!, of: firstBilling)!
            if currentMonthBilling.compare(today) != .orderedAscending && currentMonthBilling.compare(endOfCurrentMonth) != .orderedDescending {
                return true
            }
        case .quarterly:
            let components = Calendar.current.dateComponents([.year, .quarter], from: today)
            var nextBilling = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            nextBilling = Calendar.current.date(bySetting: .quarter, value: components.quarter!, of: nextBilling)!
            if nextBilling.compare(today) != .orderedAscending && nextBilling.startOfMonth() == startOfCurrentMonth {
                return true
            }
        case .everySixMonths:
            let components = Calendar.current.dateComponents([.year, .weekOfYear], from: today)
            var nextBillingOpt1 = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            nextBillingOpt1 = Calendar.current.date(bySetting: .weekOfYear, value: components.weekOfYear!, of: nextBillingOpt1)!
            let nextBillingOpt2 = Calendar.current.date(byAdding: .weekOfYear, value: 52 / 2, to: nextBillingOpt1)!
            let nextBillingOpt3 = Calendar.current.date(byAdding: .weekOfYear, value: 52 / 2 * -1, to: nextBillingOpt1)!
            if (nextBillingOpt1.compare(today) != .orderedAscending && nextBillingOpt1.startOfMonth() == startOfCurrentMonth) ||
                (nextBillingOpt2.compare(today) != .orderedAscending && nextBillingOpt2.startOfMonth() == startOfCurrentMonth) ||
                (nextBillingOpt3.compare(today) != .orderedAscending && nextBillingOpt3.startOfMonth() == startOfCurrentMonth) {
                return true
            }
        case .annually:
            let components = Calendar.current.dateComponents([.year], from: today)
            let currentYearBilling = Calendar.current.date(bySetting: .year, value: components.year!, of: firstBilling)!
            if currentYearBilling.compare(today) != .orderedAscending && currentYearBilling.startOfMonth() == startOfCurrentMonth {
                return true
            }
        case .custom:
            let roundedBilling = Int(item.billing.rounded(.down))
            var currentDateAtLoop = firstBilling
            while currentDateAtLoop.compare(endOfCurrentMonth) != .orderedDescending {
                if currentDateAtLoop.compare(today) != .orderedAscending {
                    return true
                }
                currentDateAtLoop = Calendar.current.date(byAdding: .day, value: roundedBilling, to: currentDateAtLoop)!
            }
        }
    }
    
    return false
}

struct SubscriptionDetailView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.calendar) var calendar
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    
    @ObservedObject var item: Item
    
    @State private var editing = false
    @State private var confirmDeletion = false
    
    var relativeDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.formattingContext = .middleOfSentence
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.doesRelativeDateFormatting = true
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
        List {
            HStack {
                Spacer()
                if let icon = item.icon, let image = UIImage(data: icon) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .if(roundedIconBorders) {
                            $0.cornerRadius(5)
                        }
                } else if let systemImage = item.systemImage, systemImage.count > 0 {
                    Image(systemName: systemImage)
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 50, height: 50)
                        .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
                } else {
                    Image(systemName: "questionmark")
                        .resizable()
                        .scaledToFit()
                        .symbolVariant(.square)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 50, height: 50)
                        .foregroundColor(item.color != nil ? Color(hex: item.color!) : .accentColor)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
            
            if let note = item.note, note.count > 0 {
                Section {
                    Text(.init(note))
                } header: {
                    Text("Note")
                }
            }
            
            Section {
                if let cost = item.cost?.decimalValue, let billing = item.billing {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Group {
                            Text(cost as NSDecimalNumber, formatter: currencyFormatter) +
                            Text(" ") +
                            Text(BillingLabel(BillingOption(billing)).localizedString())
                        }
                        .font(.body.weight(.semibold))
                    }
                }
                if let billing = item.billing {
                    if let nextBill = getNextBill(item, circle: BillingOption(billing)) {
                        HStack {
                            Text("Next Bill")
                            Spacer()
                            Text(nextBill, formatter: relativeDateFormatter)
                        }
                    }
                    if let lastBill = getPreviousBill(item, circle: BillingOption(billing)) {
                        if let firstBill = item.lastBillDate, calendar.startOfDay(for: lastBill).compare(calendar.startOfDay(for: firstBill)) != .orderedAscending {
                            HStack {
                                Text("Previous Bill")
                                Spacer()
                                Text(lastBill, formatter: relativeDateFormatter)
                            }
                        }
                    }
                    if let cancellationDate = item.deactivationDate {
                        if cancellationDate.compare(calendar.startOfDay(for: .now)) == .orderedDescending {
                            Text("Will be paused ")
                            Spacer()
                            Text(cancellationDate, formatter: relativeDateFormatter)
                        } else {
                            Text("Paused since ")
                            Spacer()
                            Text(cancellationDate, formatter: relativeDateFormatter)
                        }
                    }
                }
            } footer: {
                if let timestamp = item.timestamp {
                    Text("Subscription added at \(timestamp, formatter: itemFormatter)")
                        .font(.footnote)
                }
            }
            
            Section {
                if let cancellationUrl = item.cancellationUrl {
                    Link(destination: cancellationUrl) {
                        Label("Cancel this Subscription", systemImage: "xmark.circle")
                    }
                }
                
                Button {
                    withAnimation {
                        item.pinned.toggle()
                        try? viewContext.save()
                    }
                } label: {
                    if item.pinned {
                        Label("Unpin this Subscription", systemImage: "pin.slash")
                    } else {
                        Label("Pin this Subscription", systemImage: "pin")
                    }
                }
                
                Button {
                    withAnimation {
                        item.active.toggle()
                        item.deactivationDate = item.active ? nil : .now
                        try? viewContext.save()
                    }
                } label: {
                    if item.active {
                        Label("Pause this Subscription", systemImage: "pause")
                    } else {
                        Label("Resume this Subscription", systemImage: "play")
                        
                    }
                }
            } header: {
                Text("Actions")
            } footer: {
                Text("Once paused, you can resume a subscription at any time in the future.")
            }
            
            Section {
                Button {
                    confirmDeletion.toggle()
                } label: {
                    Label("Delete this Subscription", systemImage: "trash")
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.red)
            } footer: {
                Text("Deleting a Subscription will completely remove it forever.")
            }
        }
        .navigationTitle(item.title ?? "Unnamed")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editing.toggle()
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $editing) {
            SubscriptionForm(item: item)
        }
        .actionSheet(isPresented: $confirmDeletion) {
            if item.active {
                return ActionSheet(title: Text("Are you sure?"),
                            message: Text("This will remove the subscription permanently, it's recommended to pause it instead."),
                                   buttons: [.cancel(), .default(Text("Pause this Subscription"), action: {
                    withAnimation {
                        item.active = false
                        item.deactivationDate = .now
                        try? viewContext.save()
                    }
                }), .destructive(Text("Delete this Subscription"), action: {
                    withAnimation {
                        viewContext.delete(item)
                        try? viewContext.save()
                        dismiss()
                    }
                })])
            } else {
                return ActionSheet(title: Text("Are you sure?"),
                            message: Text("This will remove the subscription permanently."),
                                   buttons: [.cancel(), .destructive(Text("Delete this Subscription"), action: {
                    withAnimation {
                        viewContext.delete(item)
                        try? viewContext.save()
                        dismiss()
                    }
                })])
            }
        }
    }
}
