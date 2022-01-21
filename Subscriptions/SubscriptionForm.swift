//
//  SubscriptionForm.swift
//  Subscriptions
//
//  Created by Timo Zacherl on 07.01.22.
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
                SubscriptionDetailsForm(dismiss: _dismiss, item: item, title: $title, note: $note, cost: $cost, editMode: $editMode, showAdvancedOptions: $showAdvancedOptions, billingCircle: $billingCircle, customBillingCircle: $customBillingCircle, color: $color, lastBillDate: $lastBillDate, showIconPicker: $showIconPicker, icon: $icon, currency: $currency, url: $url, cancellationUrl: $cancellationUrl, deactivationDate: $deactivationDate, withDeactivationDate: $withDeactivationDate, iconIsSfSymbol: $iconIsSfSymbol, iconSfSymbol: $iconSfSymbol)
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
                                SubscriptionDetailsForm(dismiss: _dismiss, title: $title, note: $note, cost: $cost, editMode: $editMode, showAdvancedOptions: $showAdvancedOptions, billingCircle: $billingCircle, customBillingCircle: $customBillingCircle, color: $color, lastBillDate: $lastBillDate, showIconPicker: $showIconPicker, icon: $icon, currency: $currency, url: $url, cancellationUrl: $cancellationUrl, deactivationDate: $deactivationDate, withDeactivationDate: $withDeactivationDate, iconIsSfSymbol: $iconIsSfSymbol, iconSfSymbol: $iconSfSymbol)
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
            IconPicker(image: $icon, systemImage: $iconSfSymbol, isSystemImage: $iconIsSfSymbol, color: $color)
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

extension Color {
    static var placeholderText = Color(uiColor: .placeholderText)
    static var link = Color(uiColor: .link)
    static var label = Color(uiColor: .label)
    static var secondaryLabel = Color(uiColor: .secondaryLabel)
    static var secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static var secondarySystemGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
}

class Currency {
    static let shared: Currency = Currency()

    private var cache: [String:String] = [:]

    func findSymbol(currencyCode:String) -> String {
        if let hit = cache[currencyCode] { return hit }
        guard currencyCode.count < 4 else { return "" }

        let symbol = findSymbolBy(currencyCode)
        cache[currencyCode] = symbol

        return symbol
    }

    private func findSymbolBy(_ currencyCode: String) -> String {
        var candidates: [String] = []
        let locales = NSLocale.availableLocaleIdentifiers

        for localeId in locales {
            guard let symbol = findSymbolBy(localeId, currencyCode) else { continue }
            if symbol.count == 1 { return symbol }
            candidates.append(symbol)
        }

        return candidates.sorted(by: { $0.count < $1.count }).first ?? ""
    }

    private func findSymbolBy(_ localeId: String, _ currencyCode: String) -> String? {
        let locale = Locale(identifier: localeId)
        return currencyCode.caseInsensitiveCompare(locale.currencyCode ?? "") == .orderedSame
            ? locale.currencySymbol : nil
    }
}

extension String {
    var currencySymbol: String { return Currency.shared.findSymbol(currencyCode: self) }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

enum BillingOption: Int, CaseIterable, Hashable {
    case daily = 1
    case weekly = 7
    case monthly = 30
    case quarterly = 90
    case everySixMonths = 180
    case annually = 365
    case custom = -1
    
    init(_ number: Double) {
        if number.truncatingRemainder(dividingBy: 1.0) != 0 {
            self = .custom
        } else {
            let int = Int(number)
            if int < 7 {
                self = .daily
            } else if int < 30 {
                self = .weekly
            } else if int < 90 {
                self = .monthly
            } else if int < 180 {
                self = .quarterly
            } else if int < 365 {
                self = .everySixMonths
            } else {
                self = .annually
            }
        }
    }
}

enum BillingLabel: String {
    case daily
    case weekly
    case monthly
    case quarterly
    case everySixMonths = "every six months"
    case annually
    case custom
    
    init(_ option: BillingOption) {
        switch option {
        case .daily:
            self = .daily
        case .weekly:
            self = .weekly
        case .monthly:
            self = .monthly
        case .quarterly:
            self = .quarterly
        case .everySixMonths:
            self = .everySixMonths
        case .annually:
            self = .annually
        case .custom:
            self = .custom
        }
    }
    
    func localizedString() -> String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

extension Color {

    // MARK: - Initialization

    init?(hex: String) {
        var hexNormalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexNormalized = hexNormalized.replacingOccurrences(of: "#", with: "")

        // Helpers
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        let length = hexNormalized.count

        // Create Scanner
        Scanner(string: hexNormalized).scanHexInt64(&rgb)

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    // MARK: - Convenience Methods
    
    var hex: String? {
        // Extract Components
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        // Helpers
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        // Create Hex String
        let hex = String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))

        return hex
    }
}

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
