// 
//  SubscriptionDetailView.swift
//  Subscriptions
// 
//  Created by Timo Zacherl on 11.02.22.
// 
//  Copyright © 2022 Timo Zacherl. All rights reserved.
// 
//  This program is licensed under the GPL-3.0 License.
//  A copy of that license should be attached to the bundle.
//  If not, see <https://www.gnu.org/licenses/>
// 

import SwiftUI

struct SubscriptionDetailView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.calendar) var calendar
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: false)], animation: .default)
    private var categories: FetchedResults<Category>
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.timestamp, ascending: false)], animation: .default)
    private var tags: FetchedResults<Tag>
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    @AppStorage("privacyMode") private var privacyMode = false
    
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @ObservedObject var item: Item
    
    @State private var editing = false
    @State private var confirmDeletion = false
    @State private var selectedCategory: Category?
    @State private var tagSearchText = ""
    @State private var searchingTag = false
    
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
    
    private var foundTags: [Tag] {
        let usableTags = Array(tags.filter { !(item.tags ?? []).contains($0) })
        if tagSearchText.isEmpty {
            return usableTags
        } else {
            return usableTags.filter {
                ($0.name ?? "").lowercased().contains(tagSearchText.lowercased())
            }
        }
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
                        .privacySensitive()
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
                        HStack {
                            if cancellationDate.compare(calendar.startOfDay(for: .now)) == .orderedDescending {
                                Text("Will be paused ")
                            } else {
                                Text("Paused since ")
                            }
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
                Picker(selection: $selectedCategory) {
                    ForEach(categories) { category in
                        HStack {
                            Label {
                                Text(category.name ?? "Unnamed")
                            } icon: {
                                if let hex = category.color, let color = Color(hex: hex) {
                                    Image(systemName: "square.inset.filled")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(color)
                                } else {
                                    Image(systemName: "square.inset.filled")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .tag(category as Category?)
                    }
                } label: {
                    Text("Category")
                }
                .onChange(of: selectedCategory) { _ in
                    item.category = selectedCategory
                    try? viewContext.save()
                }
                HStack {
                    if !searchingTag {
                        Text("Tags")
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(Array(item.tags! as! Set<Tag>), id: \.id) { tag in
                                    HStack {
                                        Text(tag.name ?? "Unnamed")
                                        Button {
                                            withAnimation {
                                                tag.removeFromItems(item)
                                                try? viewContext.save()
                                            }
                                        } label: {
                                            Label("Remove tag", systemImage: "xmark.circle")
                                                .labelStyle(.iconOnly)
                                                .foregroundColor(.red)
                                        }
                                        .padding(2)
                                        .background(.regularMaterial)
                                        .cornerRadius(15)
                                    }
                                    .padding(5)
                                    .if(tag.color != nil && Color(hex: tag.color!) != nil) {
                                        $0.background(Color(hex: tag.color!))
                                    }
                                    .if(tag.color == nil || Color(hex: tag.color!) == nil) {
                                        $0.background(Color.accentColor)
                                    }
                                    .cornerRadius(10)
                                }
                            }
                        }
                    } else {
                        TextField("Search a tag...", text: $tagSearchText)
                        Text("\((item.tags ?? []).count)")
                    }
                    Button {
                        withAnimation {
                            tagSearchText = ""
                            searchingTag.toggle()
                        }
                    } label: {
                        if searchingTag {
                            Label("Cancel search", systemImage: "xmark.circle")
                                .labelStyle(.iconOnly)
                        } else {
                            Label("Add tag", systemImage: "plus.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                if searchingTag && !foundTags.isEmpty {
                    ForEach(foundTags) { tag in
                        Button {
                            tag.addToItems(item)
                            try? viewContext.save()
                        } label: {
                            Label {
                                Text(tag.name ?? "Unnamed")
                            } icon: {
                                if let hex = tag.color, let color = Color(hex: hex) {
                                    Image(systemName: "tag.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(color)
                                } else {
                                    Image(systemName: "tag.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .foregroundColor(.label)
                        }
                    }
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
                .environmentObject(notificationScheduler)
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
        .onAppear {
            selectedCategory = item.category
        }
    }
}

struct SubscriptionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionDetailView(item: Item())
    }
}
