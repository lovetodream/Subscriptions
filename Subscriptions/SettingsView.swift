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

struct SettingsView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    @AppStorage("currency") private var currency: String = Locale.current.currencyCode ?? "USD"
    @AppStorage("useCloudKitSync") private var icloudSync = false
    @AppStorage(Bundle.main.object(forInfoDictionaryKey: "premiumIAP") as! String) private var lifetimePremium = false
    @AppStorage("monthlyBudget") private var budget = 0.0
    @AppStorage("monthlyBudgetActive") private var budgetActive = false
    @AppStorage("roundedIconBorders") private var roundedIconBorders = true
    
    private var licenses: [License] = [License(product: "FaviconFinder", content: "", url: URL(string: "https://raw.githubusercontent.com/OpenSesameManager/FaviconFinder/4.0.4/LICENSE.txt")!),
                                       License(product: "SwiftSoup", content: "", url: URL(string: "https://raw.githubusercontent.com/scinfu/SwiftSoup/2.3.6/LICENSE")!)]
    
    @State private var selectedLicense: License?
    @State private var loadingLicense: License?
    
    @State private var failedAttempts: CGFloat = 0.0
    @State private var showPremiumIAP = false
    @State private var confirmErasing = false
    @State private var showTipJar = false
    
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
                
                Section {
                    Toggle(isOn: $icloudSync) {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                    .onChange(of: icloudSync) { newValue in
                        if newValue && !lifetimePremium {
                            withAnimation {
                                icloudSync = false
                                showPremiumIAP.toggle()
                            }
                        }
                    }
                } footer: {
                    Text("Enabling iCloud Sync will allow your subscriptions to stay in sync across all your devices.")
                }
                
                Section {
                    Toggle(isOn: $roundedIconBorders) {
                        Label("Rounded Borders on Icons", systemImage: "app")
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
                    List {
                        Section {
                            ForEach(licenses) { license in
                                HStack {
                                    Text(license.product)
                                    Spacer()
                                    Button {
                                        withAnimation {
                                            loadingLicense = license
                                        }
                                        getLicense(for: license.url) { lic in
                                            if let lic = lic {
                                                withAnimation {
                                                    loadingLicense = nil
                                                    self.selectedLicense = License(product: license.product, content: lic, url: license.url)
                                                }
                                            } else {
                                                withAnimation {
                                                    failedAttempts += 1
                                                }
                                            }
                                        }
                                    } label: {
                                        if loadingLicense == license {
                                            ProgressView()
                                        } else {
                                            Text("Show License")
                                        }
                                    }
                                    .disabled(loadingLicense != nil)
                                }
                            }
                        }
                        .modifier(Shake(animatableData: failedAttempts))
                    }
                    .navigationTitle("Acknowledgements")
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
            .sheet(item: $selectedLicense) { license in
                NavigationView {
                    ScrollView {
                        Text(license.content)
                            .lineLimit(.none)
                            .monospacedDigit()
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .padding()
                    }
                    .navigationTitle(license.product)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            CloseButton(fill: .secondarySystemBackground) {
                                withAnimation {
                                    self.selectedLicense = nil
                                }
                            }
                        }
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
        }
    }
    
    private func getLicense(for url: URL?, completion: @escaping (String?) -> ()) {
        guard let url = url else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                completion(nil)
                return
            }
            
            let license = String(data: data, encoding: .utf8)
            
            completion(license)
        }

        task.resume()
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
            print("Detele all data in \(entity) error :", error)
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

struct CloseButton: View {
    var fill: Color = .secondarySystemGroupedBackground
    var action: () -> ()
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 30, height: 30)
                
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .contentShape(Circle())
        })
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text("Close"))
    }
}

struct License: Identifiable, Equatable {
    var id = UUID()
    var product: String
    var content: String
    var url: URL
}

struct SearchBar: UIViewRepresentable {

    @Binding var text: String
    var placeholder: String

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator

        searchBar.placeholder = placeholder
        searchBar.autocapitalizationType = .none
        searchBar.searchBarStyle = .minimal
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }
}
