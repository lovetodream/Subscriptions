// 
//  SubscriptionDetailsForm.swift
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
import CoreData

struct SubscriptionDetailsForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    var item: Item?
    
    @Binding var title: String
    @Binding var note: String
    @Binding var cost: Double
    @FocusState var focusedField: Field?
    @Binding var editMode: Bool
    @Binding var showAdvancedOptions: Bool
    @Binding var billingCircle: BillingOption
    @Binding var customBillingCircle: Int
    @Binding var color: Color
    @Binding var lastBillDate: Date
    @Binding var showIconPicker: Bool
    @Binding var icon: UIImage
    @Binding var currency: String
    @Binding var url: URL?
    @Binding var cancellationUrl: String
    @Binding var deactivationDate: Date
    @Binding var withDeactivationDate: Bool
    @Binding var iconIsSfSymbol: Bool
    @Binding var iconSfSymbol: String
    @Binding var reminders: [ReleasedReminder]
    @Binding var cancellationReminders: [ReleasedCancellationReminder]
    
    @State var reminderWarning = false
    
    var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        Form {
            TextField("Title", text: $title)
            
            Section {
                TextEditor(text: $note)
            } header: {
                Text("Note")
            }
            
            Section {
                HStack {
                    TextField("Cost", value: $cost, formatter: numberFormatter)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .cost)
                    Text(currency.currencySymbol)
                    Picker(selection: $billingCircle) {
                        ForEach(BillingOption.allCases, id: \.self) { option in
                            Group {
                                switch option {
                                case .daily:
                                    Text("daily")
                                case .weekly:
                                    Text("weekly")
                                case .monthly:
                                    Text("monthly")
                                case .quarterly:
                                    Text("quarterly")
                                case .everySixMonths:
                                    Text("every six months")
                                case .annually:
                                    Text("annually")
                                case .custom:
                                    Text("custom circle")
                                }
                            }
                            .id(option)
                        }
                    } label: {
                        Text("Billed")
                    }
                    .pickerStyle(.menu)
                }
                .task {
                    if !editMode {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            focusedField = .cost
                        }
                    }
                }
                if billingCircle == .custom {
                    HStack {
                        TextField("Days", value: $customBillingCircle, format: .number)
                        Text("days")
                    }
                }
                DatePicker("Date of last bill", selection: $lastBillDate, displayedComponents: .date)
                
                if showAdvancedOptions {
                    Button {
                        let id = reminders.count + 1
                        let newReminder = ReleasedReminder(id: id,
                                                           daysBefore: id)
                        withAnimation {
                            reminders.append(newReminder)
                        }
                    } label: {
                        if reminders.count > 0 {
                            Text("Add another reminder")
                        } else {
                            if title.isEmpty {
                                Text("Add a due date reminder for \"Unnamed\"")
                            } else {
                                Text("Add a due date reminder for \"\(title)\"")
                            }
                        }
                    }
                    .onChange(of: reminders.count) { [reminders] newCount in
                        if newCount > 3 && newCount > reminders.count {
                            withAnimation {
                                reminderWarning = true
                            }
                        }
                    }
                    .alert("Warning", isPresented: $reminderWarning) {
                        Button("Ok", role: .cancel) {
                            withAnimation {
                                reminderWarning = false
                            }
                        }
                    } message: {
                        Text("You should avoid adding more than 3 notifications to a single subscription")
                    }
                    
                    ForEach($reminders) { reminder in
                        HStack {
                            TextField("0", value: reminder.daysBefore, format: .number)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 25)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.tertiarySystemGroupedBackground)
                                .cornerRadius(5)
                            if reminder.daysBefore.wrappedValue == 1 {
                                Text("day before next bill")
                            } else {
                                Text("days before next bill")
                            }
                            Spacer()
                            Button {
                                withAnimation {
                                    reminders.removeAll { $0.id == reminder.wrappedValue.id }
                                }
                            } label: {
                                Label("Remove", systemImage: "minus.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { indexSet in
                        reminders.remove(atOffsets: indexSet)
                    }
                }
            } header: {
                Text("Cost")
            }
            
            
            if showAdvancedOptions {
                Section {
                    ColorPicker("Color", selection: $color)
                    Button {
                        withAnimation {
                            showIconPicker.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Icon")
                            Spacer()
                            if iconIsSfSymbol {
                                Image(systemName: iconSfSymbol)
                                    .symbolRenderingMode(.hierarchical)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 24)
                                    .foregroundColor(color)
                            } else {
                                Image(uiImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 24)
                            }
                        }
                        .foregroundColor(.label)
                    }
                } header: {
                    Text("Cosmetics")
                }
                
                Section {
                    TextField("Cancellation URL", text: $cancellationUrl)
                        .keyboardType(.URL)
                    if withDeactivationDate {
                        DatePicker("Subscription ends on", selection: $deactivationDate, displayedComponents: .date)
                            .focused($focusedField, equals: .cancellationUrl)
                    }
                    Button {
                        withAnimation {
                            withDeactivationDate.toggle()
                            if withDeactivationDate {
                                focusedField = .cancellationUrl
                            }
                        }
                    } label: {
                        if withDeactivationDate {
                            Text("Remove end date")
                        } else {
                            Text("Add end date")
                        }
                    }
                    
                    Button {
                        let newReminder = ReleasedCancellationReminder(id: cancellationReminders.count + 1, date: deactivationDate)
                        withAnimation {
                            cancellationReminders.append(newReminder)
                        }
                    } label: {
                        if cancellationReminders.count > 0 {
                            Text("Add another reminder")
                        } else {
                            if title.isEmpty {
                                Text("Add a reminder to cancel \"Unnamed\"")
                            } else {
                                Text("Add a reminder to cancel \"\(title)\"")
                            }
                        }
                    }
                    .onChange(of: cancellationReminders.count) { [cancellationReminders] newCount in
                        if newCount > 3 && newCount > cancellationReminders.count {
                            withAnimation {
                                reminderWarning = true
                            }
                        }
                    }
                    .alert("Warning", isPresented: $reminderWarning) {
                        Button("Ok", role: .cancel) {
                            withAnimation {
                                reminderWarning = false
                            }
                        }
                    } message: {
                        Text("You should avoid adding more than 3 notifications to a single subscription")
                    }
                    
                    ForEach($cancellationReminders) { reminder in
                        DatePicker(selection: reminder.date) {
                            Button {
                                withAnimation {
                                    cancellationReminders.removeAll { $0.id == reminder.wrappedValue.id }
                                }
                            } label: {
                                Label("Remove", systemImage: "minus.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { indexSet in
                        cancellationReminders.remove(atOffsets: indexSet)
                    }
                } header: {
                    Text("Advanced")
                }
            }
            
            Button {
                withAnimation {
                    showAdvancedOptions.toggle()
                }
            } label: {
                if showAdvancedOptions {
                    Text("Hide advanced options")
                } else {
                    Text("Show advanced options")
                }
            }
        }
        .navigationTitle(title.isEmpty ? "Unnamed" : title)
        .navigationBarBackButtonHidden(editMode)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .if(!editMode) {
                    $0.hidden()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: editMode ? updateItem : addItem) {
                    Text("Save")
                }
            }
        }
    }
    
    private func updateItem() {
        withAnimation {
            if let item = item {
                item.cost = NSDecimalNumber(value: cost)
                if billingCircle == .custom {
                    // Note: a custom billing circle is marked with a .1
                    item.billing = Double(customBillingCircle) + 0.1
                } else {
                    item.billing = Double(billingCircle.rawValue)
                }
                item.color = color.hex
                item.currencyCode = currency
                item.note = note
                item.title = title
                item.active = true
                item.deactivationDate = withDeactivationDate ? deactivationDate : nil
                item.lastBillDate = lastBillDate
                if iconIsSfSymbol {
                    item.systemImage = iconSfSymbol
                } else if icon != UIImage(systemName: "questionmark.square.dashed") {
                    item.icon = icon.pngData()
                }
                if let cancellation = URL(string: cancellationUrl) {
                    item.cancellationUrl = cancellation
                }
                if let serviceUrl = url {
                    item.serviceUrl = serviceUrl
                }
                
                item.reminders?.forEach { viewContext.delete($0 as! NSManagedObject) }
                item.cancellationReminders?.forEach { viewContext.delete($0 as! NSManagedObject) }
                
                reminders.forEach { reminder in
                    let newReminder = Reminder(context: viewContext)
                    newReminder.daysBefore = Int16(reminder.daysBefore)
                    newReminder.item = item
                }
                
                cancellationReminders.forEach { reminder in
                    let newReminder = CancellationReminder(context: viewContext)
                    newReminder.onDate = reminder.date
                    newReminder.item = item
                }
                
                do {
                    try viewContext.save()
                    dismiss()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.cost = NSDecimalNumber(value: cost)
            if billingCircle == .custom {
                // Note: a custom billing circle is marked with a .1
                newItem.billing = Double(customBillingCircle) + 0.1
            } else {
                newItem.billing = Double(billingCircle.rawValue)
            }
            newItem.color = color.hex
            newItem.currencyCode = currency
            newItem.note = note
            newItem.title = title
            newItem.active = true
            newItem.deactivationDate = withDeactivationDate ? deactivationDate : nil
            newItem.lastBillDate = lastBillDate
            if iconIsSfSymbol {
                newItem.systemImage = iconSfSymbol
            } else if icon != UIImage(systemName: "questionmark.square.dashed") {
                newItem.icon = icon.pngData()
            }
            if let cancellation = URL(string: cancellationUrl) {
                newItem.cancellationUrl = cancellation
            }
            if let serviceUrl = url {
                newItem.serviceUrl = serviceUrl
            }
            
            reminders.forEach { reminder in
                let newReminder = Reminder(context: viewContext)
                newReminder.daysBefore = Int16(reminder.daysBefore)
                newReminder.item = newItem
            }
            
            cancellationReminders.forEach { reminder in
                let newReminder = CancellationReminder(context: viewContext)
                newReminder.onDate = reminder.date
                newReminder.item = newItem
            }

            do {
                try viewContext.save()
                dismiss()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct SubscriptionDetailsForm_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionDetailsForm(title: .constant("Apple ONE"),
                                note: .constant("The most pricy plan"),
                                cost: .constant(28.95),
                                editMode: .constant(true),
                                showAdvancedOptions: .constant(true),
                                billingCircle: .constant(BillingOption.monthly),
                                customBillingCircle: .constant(0),
                                color: .constant(.accentColor),
                                lastBillDate: .constant(.now),
                                showIconPicker: .constant(false),
                                icon: .constant(UIImage(systemName: "applelogo")!),
                                currency: .constant("EUR"),
                                url: .constant(URL(string: "https://apple.com")),
                                cancellationUrl: .constant(""),
                                deactivationDate: .constant(.now),
                                withDeactivationDate: .constant(false),
                                iconIsSfSymbol: .constant(true),
                                iconSfSymbol: .constant("applelogo"),
                                reminders: .constant([]),
                                cancellationReminders: .constant([]))
    }
}

extension Binding {
    func safeBinding<T>(defaultValue: T) -> Binding<T> where Value == Optional<T> {
        Binding<T>.init {
            self.wrappedValue ?? defaultValue
        } set: { newValue in
            self.wrappedValue = newValue
        }
    }
}

public extension Int {
      var written: String? {
          let numberValue = NSNumber(value: self)
          let formatter = NumberFormatter()
          formatter.numberStyle = .spellOut
          return formatter.string(from: numberValue)
      }
}

struct ReleasedReminder: Identifiable {
    var id: Int
    var daysBefore: Int
}

struct ReleasedCancellationReminder: Identifiable {
    var id: Int
    var date: Date
}
