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
                            BillView(showSettings: $showSettings, cost: cost, budget: budget)
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

struct BillView: View {
    init(showSettings: Binding<Bool>, cost: Decimal, budget: Decimal) {
        self._showSettings = showSettings
        self.cost = cost
        self.budget = budget
    }
    
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
